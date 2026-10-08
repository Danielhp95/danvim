-- danvim.codecompanion_qwen_adapter -- two fixes to CodeCompanion's ollama adapter
-- for running Qwen3-Coder through Ollama, as extensions of that adapter.
--
-- 1. chat_output / form_tools: recover tool calls that Ollama drops.
--    Qwen3-Coder writes a call as `<function=NAME><parameter=K>V</parameter>...`
--    text. Ollama converts it to `tool_calls`, but only when it sees the single
--    `<tool_call>` token first (ollama#18530), and the model sometimes skips that
--    token after a line of prose. The reply is then HTTP 200 with the XML in
--    `content` and empty `tool_calls`; CodeCompanion continues an agent turn only
--    when there are tool calls, so the turn just stops. Here the XML is withheld
--    from the buffer as it streams, and at the end it is parsed (danvim.qwen_xml)
--    into `tools` entries BEFORE Chat:done() decides whether the turn is over, so
--    the chat runs the tools and carries on as if Ollama had parsed them.
--    A strict-XML failure inside Ollama (ollama#18563: a dropped </parameter>, or
--    the `edits` array of the stock edit tool) cannot be recovered here, because
--    Ollama discards the text; danvim.codecompanion_tools avoids that shape.
--
-- 2. output_response: pair every tool result with its call.
--    See the function below; without it each turn of the loop adds a fake
--    "did not complete" result for every earlier call.
--
-- Both are installed through `adapters.http.extend.ollama.handlers` (wiring below).
--
-- Wiring (the user's existing adapters.http.extend.ollama block; the closures
-- defer the require() to call time because lazy.nvim evaluates `opts` before the
-- plugin is on the runtimepath):
--
--   extend = { ollama = {
--     handlers = {
--       form_tools  = function(...) return require("danvim.codecompanion_qwen_adapter").form_tools(...) end,
--       chat_output = function(...) return require("danvim.codecompanion_qwen_adapter").chat_output(...) end,
--       tools = {  -- merged into the stock tools namespace; does not trigger the nested format
--         output_response = function(...) return require("danvim.codecompanion_qwen_adapter").output_response(...) end,
--       },
--     },
--     schema = { ... unchanged ... },
--   } }
--
-- Use the FLAT handler names. adapters/http/init.lua get_handler() switches to
-- the nested lookup (lifecycle/request/response/tools only) the moment
-- handlers.response/.request/.lifecycle exists, and every flat handler of the
-- stock ollama adapter would silently disappear.
--
-- Safe against recursion: Adapter.extend() deep-copies the module table before
-- applying the patch, so require("codecompanion.adapters.http.ollama").handlers
-- is always the stock set.
--
-- Tested by tests/qwen_adapter_test.lua, which simulates the per-request adapter
-- copy, and by running a real chat (see the header of that file).

local xml = require("danvim.qwen_xml")

local M = {}

-- Per-request state keyed by the `tools` accumulator that Chat:_submit_http
-- creates fresh for every request and passes to every parse_chat call.
local STATE = setmetatable({}, { __mode = "k" })

-- Parameter schemas of the tools offered on the most recent request, by tool name.
--
-- This cannot live on the adapter: http.lua's prepare_adapter() does
-- vim.deepcopy(self.adapter) for every request and runs form_tools on THAT copy,
-- while the chat hands its own, original adapter to parse_chat. Anything stored
-- on `self` in form_tools is therefore invisible to chat_output. (An earlier
-- version did exactly that and never recovered a single call in a live chat.)
-- A module-level slot is shared by both; with one request in flight at a time
-- it is exact, and if two chats ever offer different tool sets the worst case
-- is an "unknown tool" and the text staying visible, never a wrong call.
local schemas_offered = {}

local function stock()
	return require("codecompanion.adapters.http.ollama").handlers
end

local function decode(data)
	local body = type(data) == "table" and data.body
		or require("codecompanion.adapters.utils").clean_streamed_data(data)
	local ok, json = pcall(vim.json.decode, body, { luanil = { object = true } })
	return ok and json or nil
end

---Remember the parameter schemas of the tools offered on this request.
function M.form_tools(self, tools)
	local out = stock().form_tools(self, tools)
	local schemas = {}
	for _, t in ipairs((out and out.tools) or {}) do
		local f = t["function"]
		if f and f.name then
			schemas[f.name] = f.parameters or {}
		end
	end
	schemas_offered = schemas
	return out
end

local function process(data, tools, result, schemas)
	local log = require("codecompanion.utils.log")
	local st = STATE[tools]
	if not st then
		st = { stream = xml.new_stream(), native = false }
		STATE[tools] = st
	end
	local out = result.output
	local delta = out.content or ""

	-- Ollama's own parser produced calls (or already did): stay out of the way,
	-- but release anything held back while we were still unsure.
	if #tools > 0 then
		if not st.native then
			st.native = true
			local raw, flush = st.stream:finish()
			out.content = flush .. raw .. delta
		end
		return result
	end
	if st.native then
		return result
	end

	local visible = st.stream:feed(delta)
	if out.content ~= nil or visible ~= "" then
		out.content = visible
	end

	local json = decode(data)
	if not (json and json.done) then
		return result
	end

	local raw, flush = st.stream:finish()
	STATE[tools] = nil
	out.content = (out.content or "") .. flush
	if raw == "" then
		return result
	end

	local calls, remainder, problems = xml.to_tool_calls(raw, schemas)
	if json.done_reason == "length" then
		calls = nil
		problems[#problems + 1] = "generation stopped at the length limit"
	end
	if calls then
		for _, c in ipairs(calls) do
			tools[#tools + 1] = c
		end
		if remainder ~= "" then
			out.content = out.content .. "\n\n" .. remainder
		end
		log:info("[qwen_xml] recovered %d tool call(s) from message content", #calls)
	else
		-- Anything we cannot trust stays visible text, exactly like today.
		out.content = out.content .. "\n\n" .. raw
		log:warn("[qwen_xml] left as text: %s", table.concat(problems, "; "))
	end
	return result
end

---Tag a tool result with the id of the call it answers.
---
---The stock ollama handler (19.27.0) builds the result message without
---`tools.call_id`, unlike the openai adapter. Chat:_orphaned_tool_calls() pairs
---results with calls through exactly that field, so with it missing EVERY earlier
---call looks unanswered, and each turn of the agent loop appends a stand-in
---"This tool call did not complete and produced no result" for all of them: one
---after the first turn, two after the second, three after the third. The model is
---told its tools keep failing (and re-reads files, apologises, or gives up), and
---the context grows for nothing. The field is not sent to Ollama:
---form_messages whitelists role/content/tool_calls/images.
function M.output_response(self, tool_call, output)
	local msg = stock().tools.output_response(self, tool_call, output)
	msg.tools = {
		call_id = require("codecompanion.adapters.utils").pairing_id(tool_call),
		name = tool_call["function"].name,
	}
	return msg
end

function M.chat_output(self, data, tools)
	local result = stock().chat_output(self, data, tools)
	local schemas = schemas_offered
	-- tools == nil: inline/cmd. No schemas: no tools were offered. Stock behaviour both ways.
	if not (result and result.status == "success" and tools and self.opts.tools and schemas and next(schemas)) then
		return result
	end
	local ok, res = pcall(process, data, tools, result, schemas)
	if not ok then
		require("codecompanion.utils.log"):warn("[qwen_xml] fell back to stock behaviour: %s", res)
		return result
	end
	return res
end

return M
