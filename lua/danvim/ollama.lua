-- danvim.ollama: the local model's identity, and a non-blocking preload for it.
--
-- `profile` is the ONE place model / num_ctx / keep_alive / think / sampling are
-- written down. plugins/codecompanion.lua feeds it into the adapter schema and
-- `warm()` feeds it into the preload request, so the two cannot drift. A drift
-- in num_ctx is exactly what makes ollama restart an already-loaded runner.
local M = {}

M.profile = {
	-- Qwen3.8 27B (dense, hybrid: only 16 of its layers keep a KV cache, so 64k of
	-- context costs ~2 GiB). The tag also carries an MTP head that ollama uses for
	-- speculative decoding (`draft_num_predict` 4); on this GPU that is worth ~3x
	-- decode speed and 4 measured as good as 2 or 3, so it is left alone. It is a
	-- runner option too: if it is ever set per request, set it here and send it in
	-- the preload as well, or every mismatch restarts the runner.
	model = "qwen3.8:27b",
	-- Keep equal to OLLAMA_CONTEXT_LENGTH in nixos/ollama.nix (belt and braces:
	-- the request carries it explicitly, so a server-side change cannot cause a
	-- mismatch).
	num_ctx = 65536,
	-- A Go duration string. NOT "-1": ollama's JSON decoder runs
	-- time.ParseDuration on strings, so the unit is mandatory ("-1m" = forever).
	keep_alive = "30m",
	-- Qwen3.8 is a thinking model. Off keeps agent turns fast (thinking would cost
	-- another ~1000 tokens, ~40 s at this speed, before every tool call), and
	-- CodeCompanion does not send the reasoning back on later turns anyway.
	think = false,
	-- The model card's NON-thinking preset. The tag bakes the thinking one
	-- (temperature 1, top_p 0.95, presence_penalty 0), so with think = false these
	-- have to be sent explicitly. Sampling options never restart the runner.
	-- https://huggingface.co/Qwen/Qwen3.8-27B
	sampling = {
		temperature = 0.7,
		top_p = 0.8,
		top_k = 20,
		presence_penalty = 1.5,
	},
}

local LOAD_TIMEOUT_S = 1200 -- well above OLLAMA_LOAD_TIMEOUT (nixos/ollama.nix). Killing curl mid-load aborts the load.
local MIN_CHECK_GAP_NS = 5e9 -- coalesce bursts of triggers (ChatCreated + wrapper + cmdline...)

local uv = vim.uv or vim.loop
local inflight = false
local last_check = nil -- hrtime of the last /api/ps we issued
local last_touch = nil -- hrtime of the last successful preload/touch
local last_down_notice = nil

---Same resolution as codecompanion's ollama adapter (`env.url`).
---@return string
function M.base_url()
	local host = os.getenv("OLLAMA_HOST")
	if host == nil or host == "" then
		host = "http://localhost:11434"
	end
	return (host:gsub("/+$", ""))
end

---Go duration string / number of seconds -> seconds (math.huge when negative).
---@param v string|number
---@return number|nil
local function duration_seconds(v)
	if type(v) == "number" then
		return v < 0 and math.huge or v
	end
	local neg = v:sub(1, 1) == "-"
	local total, found = 0, false
	for num, unit in v:gmatch("(%d+%.?%d*)(%a+)") do
		local mult = ({ h = 3600, m = 60, s = 1, ms = 0.001 })[unit]
		if not mult then
			return nil
		end
		total, found = total + tonumber(num) * mult, true
	end
	if not found then
		return nil
	end
	return neg and math.huge or total
end

---@param name string
---@return string
local function normalise(name)
	return name:find(":", 1, true) and name or (name .. ":latest")
end

---@param method "GET"|"POST"
---@param path string
---@param body table|nil
---@param max_time integer seconds
---@param cb fun(ok: boolean, data: table|nil, err: string|nil)  runs on the main loop
local function request(method, path, body, max_time, cb)
	local cmd = {
		"curl",
		"-sS",
		"--connect-timeout",
		"3",
		"--max-time",
		tostring(max_time),
		"-X",
		method,
		"-H",
		"Content-Type: application/json",
		"-w",
		"\n%{http_code}",
	}
	if body then
		vim.list_extend(cmd, { "--data-binary", "@-" })
	end
	table.insert(cmd, M.base_url() .. path)

	local ok, err = pcall(vim.system, cmd, { text = true, stdin = body and vim.json.encode(body) or nil }, function(res)
		vim.schedule(function()
			if res.code ~= 0 then
				-- 7 = connection refused, 28 = timeout, 6 = cannot resolve host
				return cb(false, nil, ("curl exit %d: %s"):format(res.code, vim.trim(res.stderr or "")))
			end
			local payload, status = (res.stdout or ""):match("^(.*)\n(%d%d%d)$")
			local decoded_ok, data = pcall(vim.json.decode, payload ~= "" and payload or "{}")
			if status ~= "200" then
				local msg = decoded_ok and type(data) == "table" and data.error or payload
				return cb(false, nil, ("HTTP %s: %s"):format(status or "?", msg))
			end
			if not decoded_ok then
				return cb(false, nil, "unparseable response: " .. tostring(payload))
			end
			cb(true, data, nil)
		end)
	end)
	if not ok then -- e.g. curl missing
		vim.schedule(function()
			cb(false, nil, tostring(err))
		end)
	end
end

---fidget when available (lazy loads it on demand), plain vim.notify otherwise.
local function progress_start(msg)
	local ok, progress = pcall(require, "fidget.progress")
	if ok then
		-- fidget groups non-LSP toasts by lsp_client.name
		return progress.handle.create({ title = "Ollama", message = msg, lsp_client = { name = "ollama" } })
	end
	vim.notify("Ollama: " .. msg, vim.log.levels.INFO)
end

local function progress_end(handle, msg, level)
	if handle then
		handle.message = msg
		handle:finish()
	end
	if not handle or level then
		vim.notify("Ollama: " .. msg, level or vim.log.levels.INFO)
	end
end

---Load (or touch) the profile's model unless it is already resident with the
---right num_ctx. Never blocks, never throws.
---@param opts? { force?: boolean, quiet?: boolean, model?: string, num_ctx?: integer, keep_alive?: string|number }
function M.warm(opts)
	opts = opts or {}
	if vim.g.ollama_warm_disabled and not opts.force then
		return
	end
	local now = uv.hrtime()
	if inflight or (not opts.force and last_check and now - last_check < MIN_CHECK_GAP_NS) then
		return
	end
	inflight, last_check = true, now

	-- Per-call overrides (a chat whose user switched model) win over the profile.
	local p = {
		model = opts.model or M.profile.model,
		num_ctx = opts.num_ctx or M.profile.num_ctx,
		keep_alive = opts.keep_alive or M.profile.keep_alive,
	}
	local want = normalise(p.model)

	request("GET", "/api/ps", nil, 3, function(ok, ps, err)
		if not ok then
			inflight = false
			-- Server down/unreachable: say so once a minute at most; the real request will
			-- surface its own error.
			if not opts.quiet and (not last_down_notice or uv.hrtime() - last_down_notice > 60e9) then
				last_down_notice = uv.hrtime()
				vim.notify("Ollama not reachable (" .. M.base_url() .. "): " .. err, vim.log.levels.WARN)
			end
			return
		end

		local loaded
		for _, m in ipairs(ps.models or {}) do
			if normalise(m.name or m.model or "") == want then
				loaded = m
			end
		end

		local ka = duration_seconds(p.keep_alive) or 300
		if
			loaded
			and (loaded.context_length == nil or loaded.context_length == p.num_ctx)
			and not opts.force
			and last_touch
			and (uv.hrtime() - last_touch) / 1e9 < ka / 2
		then
			inflight = false -- resident, right window, timer fresh: nothing to do
			return
		end

		-- Empty `messages` = "load only" (done_reason "load"). The options that
		-- decide a runner reload (num_ctx; num_batch/num_gpu/main_gpu/use_mmap/
		-- num_thread if you ever set them) must equal what CodeCompanion sends.
		local started = uv.hrtime()
		local announce = not loaded and not opts.quiet
		local handle = announce and progress_start("loading " .. p.model .. " …") or nil
		request(
			"POST",
			"/api/chat",
			{
				model = p.model,
				messages = {}, -- encodes as [] (vim.empty_dict() would encode {} and ollama rejects it)
				stream = false,
				keep_alive = p.keep_alive,
				options = { num_ctx = p.num_ctx },
			},
			LOAD_TIMEOUT_S,
			function(ok2, _, err2)
				inflight = false
				if not ok2 then
					return progress_end(handle, p.model .. ": " .. err2, vim.log.levels.WARN)
				end
				last_touch = uv.hrtime()
				if not announce then
					return
				end
				-- How much of it landed on the GPU? (size_vram < size = partial CPU offload)
				request("GET", "/api/ps", nil, 3, function(ok3, ps2)
					local where = ""
					if ok3 then
						for _, m in ipairs(ps2.models or {}) do
							if normalise(m.name or "") == want and (m.size or 0) > 0 then
								where = (", %d%% GPU"):format(math.floor(100 * (m.size_vram or 0) / m.size + 0.5))
							end
						end
					end
					progress_end(handle, ("%s ready (%.1fs%s)"):format(p.model, (uv.hrtime() - started) / 1e9, where))
				end)
			end
		)
	end)
end

---Hook up everything that should trigger a warm-up. Call once from the
---CodeCompanion spec's `init` (cheap: no CodeCompanion require).
function M.setup_triggers()
	local group = vim.api.nvim_create_augroup("danvim_ollama_warm", { clear = true })

	-- Chats (:CodeCompanionChat, Toggle, Add, actions palette -> chat): fired from
	-- inside CodeCompanion, before the user can have typed the first message.
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = { "CodeCompanionChatCreated", "CodeCompanionChatOpened", "CodeCompanionChatModel" },
		callback = function(ev)
			local d = ev.data or {}
			-- ChatModel is also fired with model = nil when a chat closes.
			if ev.match == "CodeCompanionChatModel" and not d.model then
				return
			end
			-- Events fire for every adapter (copilot, claude ACP...): only warm ollama chats,
			-- and prefer the chat's own settings, which `change_model` may have moved.
			local ok, chat = pcall(function()
				return require("codecompanion").buf_get_chat(d.bufnr)
			end)
			if not ok then
				return M.warm()
			end
			if not chat or not chat.adapter or chat.adapter.name ~= "ollama" then
				return
			end
			local s = chat.settings or {}
			M.warm({ model = s.model, num_ctx = s.num_ctx, keep_alive = s.keep_alive })
		end,
	})

	-- Inline / cmd / actions are not announced by any event before the request
	-- is already on the wire (InlineStarted/RequestStarted fire after curl was
	-- spawned). Catch the command line instead: this also covers `<leader>ae`,
	-- which parks the user on `:'<,'>CodeCompanion ` while they type the prompt.
	vim.api.nvim_create_autocmd("CmdlineChanged", {
		group = group,
		pattern = ":",
		callback = function()
			if vim.fn.getcmdline():find("CodeCompanion", 1, true) then
				M.warm()
			end
		end,
	})

	vim.api.nvim_create_user_command("CodeCompanionWarm", function()
		M.warm({ force = true })
	end, { desc = "Load the CodeCompanion model into VRAM now" })
end

---Wrap the public entry points that map-driven (`<cmd>`) use bypasses the
---cmdline for. Call from the spec's `config`, after setup().
function M.wrap_codecompanion()
	local cc = require("codecompanion")
	for _, fn in ipairs({ "inline", "cmd", "actions", "prompt" }) do
		local orig = cc[fn]
		if type(orig) == "function" then
			cc[fn] = function(...)
				pcall(M.warm)
				return orig(...)
			end
		end
	end
end

return M
