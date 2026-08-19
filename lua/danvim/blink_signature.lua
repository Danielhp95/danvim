--- Reformatting for blink.cmp's signature help window.
---
--- blink renders the `label` the LSP hands back verbatim, which for a python
--- function with a dozen keyword arguments is one 600-character line soft
--- wrapped into an unreadable block. It also throws away the per-parameter
--- documentation servers send alongside it (`ty` scrapes it out of the
--- docstring's Args: section), showing only the whole function's docstring.
---
--- blink's signature config has no formatting hook -- only border, size and
--- treesitter toggles -- so we wrap the one function that receives the LSP
--- payload on its way to the window and rewrite it there:
---   * one parameter per line, so the highlighted one is easy to find
---   * the active parameter's own doc above the function's docstring
---
--- Parameter positions come back as byte offsets into `label`, so each one has
--- to be translated into the reflowed label or the active-parameter highlight
--- lands on the wrong argument. Anything we can't translate confidently leaves
--- the signature untouched.
local M = {}

local INDENT = "  "

--- Scan from the opening paren for its match, collecting the ranges of the
--- top-level comma-separated chunks in between. Quotes are tracked so a default
--- value like `sep = ")"` doesn't unbalance the scan.
--- @return integer? close, table? parts 1-indexed, inclusive ranges
local function scan_params(label, open)
	local parts = {}
	local depth = 0
	local quote = nil
	local start = open + 1
	for i = open, #label do
		local c = label:sub(i, i)
		if quote then
			if c == quote then
				quote = nil
			end
		elseif c == '"' or c == "'" then
			quote = c
		elseif c == "(" or c == "[" or c == "{" then
			depth = depth + 1
		elseif c == ")" or c == "]" or c == "}" then
			depth = depth - 1
			if depth == 0 then
				table.insert(parts, { start = start, stop = i - 1 })
				return i, parts
			end
		elseif c == "," and depth == 1 then
			table.insert(parts, { start = start, stop = i - 1 })
			start = i + 1
		end
	end
end

--- @return integer? start, integer? stop 1-indexed, inclusive, whitespace stripped
local function trim(label, part)
	local s, e = part.start, part.stop
	while s <= e and label:sub(s, s):match("%s") do
		s = s + 1
	end
	while e >= s and label:sub(e, e):match("%s") do
		e = e - 1
	end
	if s > e then
		return nil
	end
	return s, e
end

--- The chunk whose text fully contains this parameter's 0-indexed [from, to)
--- range. Parameters and chunks don't correspond one to one: python's `/` and
--- `*` markers are chunks of the label with no parameter of their own.
local function find_part(parts, from, to)
	for _, part in ipairs(parts) do
		if part.text_start and from >= part.text_start - 1 and to <= part.text_stop then
			return part
		end
	end
end

--- @return string? the parameter's text, as it appears in `label`
local function param_text(label, param)
	if type(param.label) == "string" then
		return param.label
	end
	if type(param.label) == "table" then
		return label:sub(param.label[1] + 1, param.label[2])
	end
end

local function doc_value(doc)
	if type(doc) == "string" then
		return doc
	end
	if type(doc) == "table" then
		return doc.value
	end
end

--- Put the active parameter's documentation above the signature's own, since
--- blink only ever renders `signature.documentation`.
local function prepend_active_param_doc(help, signature)
	local active = signature.activeParameter or help.activeParameter
	if type(active) ~= "number" or active < 0 then
		return
	end
	local param = (signature.parameters or {})[active + 1]
	if not param then
		return
	end
	local doc = doc_value(param.documentation)
	if not doc or doc == "" then
		return
	end

	-- "scene_history_key: str" / "*args: int" -> "scene_history_key" / "*args"
	local text = param_text(signature.label, param)
	local name = text and text:match("^%**[%w_]+")
	local header = name and (name .. " — " .. doc) or doc

	local existing = doc_value(signature.documentation)
	signature.documentation = {
		kind = type(signature.documentation) == "table" and signature.documentation.kind or "plaintext",
		value = existing and existing ~= "" and (header .. "\n\n" .. existing) or header,
	}
end

--- Rewrite `signature.label` one parameter per line, moving every parameter
--- range along with it.
local function reflow(signature)
	local label = signature.label
	if type(label) ~= "string" or label:find("\n", 1, true) then
		return
	end
	local open = label:find("(", 1, true)
	if not open then
		return
	end
	local close, parts = scan_params(label, open)
	-- Nothing to gain from breaking up a single parameter
	if not close or not parts or #parts < 2 then
		return
	end

	-- Servers like `ty` send the parameter list with no function name in front of
	-- it, so the label opens on a bare "(". Hanging that paren, and its closing
	-- one, on lines of their own is pure noise, so we drop them and let one
	-- parameter per line carry the structure. A label that does name the function
	-- (lua_ls sends `function foo(...)`) keeps its call syntax.
	local head = label:sub(1, open)
	local bare = head:match("^%s*%($") ~= nil

	local lines = {}
	local len = 0 -- bytes written, i.e. the next 0-indexed offset
	local function push(text)
		if #lines > 0 then
			len = len + 1 -- the newline joining this line to the previous one
		end
		local start = len
		table.insert(lines, text)
		len = len + #text
		return start
	end

	if not bare then
		push(head)
	end
	for i, part in ipairs(parts) do
		local s, e = trim(label, part)
		if not s then
			return -- a stray trailing comma; leave the signature alone
		end
		part.text_start, part.text_stop = s, e
		-- The indent is load bearing, not just cosmetic: nvim's signature help
		-- converter mismaps any offset that lands on the first byte of a line
		-- (`get_pos_from_offset` tests it against the *previous* line's range and
		-- comes back nil), which silently drops the active parameter highlight.
		local sep = (not bare and i < #parts) and "," or ""
		part.new_start = push(INDENT .. label:sub(s, e) .. sep) + #INDENT
	end
	-- ") -> str" reads better as "-> str" once the parens are gone
	local tail = bare and vim.trim(label:sub(close + 1)) or label:sub(close)
	if tail ~= "" then
		push(bare and (INDENT .. tail) or tail)
	end

	-- Translate first, commit second: a parameter we can't place means the
	-- highlight would be wrong, which is worse than a long line.
	local moved = {}
	for i, param in ipairs(signature.parameters or {}) do
		if type(param.label) == "table" then
			local from, to = param.label[1], param.label[2]
			local part = find_part(parts, from, to)
			if not part then
				return
			end
			local shift = part.new_start - (part.text_start - 1)
			moved[i] = { from + shift, to + shift }
		end
	end

	signature.label = table.concat(lines, "\n")
	for i, range in pairs(moved) do
		signature.parameters[i].label = range
	end
end

--- @param help lsp.SignatureHelp
--- @return lsp.SignatureHelp a copy; blink keeps the original on its context
function M.format(help)
	if type(help) ~= "table" or type(help.signatures) ~= "table" then
		return help
	end
	local formatted = vim.deepcopy(help)
	for _, signature in ipairs(formatted.signatures) do
		-- Docs first: it reads parameter ranges against the original label
		prepend_active_param_doc(formatted, signature)
		reflow(signature)
	end
	return formatted
end

function M.setup()
	-- blink builds its source providers lazily, on the first completion request,
	-- and signature help only asks the providers that already exist. Without this,
	-- asking for a signature before having typed anything in the session -- which
	-- is the whole point of the normal mode <C-k> -- silently returns nothing.
	pcall(require("blink.cmp.sources.lib").get_provider_by_id, "lsp")

	local window = require("blink.cmp.signature.window")
	local open = window.open_with_signature_help
	window.open_with_signature_help = function(context, signature_help)
		local ok, formatted = pcall(M.format, signature_help)
		return open(context, ok and formatted or signature_help)
	end
end

return M
