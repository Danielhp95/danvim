-- qwen_xml -- Qwen3-Coder tool-call XML: scanner, schema coercion, stream holdback.
--
-- Grammar (Qwen3-Coder-30B-A3B-Instruct chat_template.jinja; Ollama's renderer
-- emits the same bytes):
--
--   call  := ["<tool_call>" NL] "<function=" NAME ">" NL param* "</function>" NL ["</tool_call>"]
--   param := "<parameter=" KEY ">" NL VALUE NL "</parameter>" NL
--
-- Real output deviates from that in four ways this module absorbs:
--   1. the single-token opener "<tool_call>" is skipped (ollama#18530)
--   2. the closer "</parameter>" is skipped before "</function>" or before the next
--      "<parameter=" (ollama#17914, #18563)
--   3. array/object arguments come out as sibling nested <parameter=...> tags
--      instead of one JSON value (ollama#18563 comment by tsnowlan)
--   4. VALUE is code, so it can contain anything, including the tag spellings
--
-- Everything here is pure Lua over strings; the only vim.* use is vim.json and
-- vim.empty_dict, so it runs under `nvim -l`.

local M = {}

local TOOL_OPEN, TOOL_CLOSE = "<tool_call>", "</tool_call>"
local FUNC_OPEN, FUNC_CLOSE = "<function=", "</function>"
local PARAM_OPEN, PARAM_CLOSE = "<parameter=", "</parameter>"
local TRIGGERS = { TOOL_OPEN, FUNC_OPEN }

local function starts_at(s, i, lit)
	return s:sub(i, i + #lit - 1) == lit
end

local function skip_ws(s, i)
	if i > #s then
		return #s + 1
	end
	local _, e = s:find("^%s*", i)
	return e + 1
end

local function at_line_start(s, i)
	if i == 1 then
		return true
	end
	local before = s:sub(1, i - 1)
	return before:match("[^\n]*$"):match("^%s*$") ~= nil
end

---Byte ranges of fenced code blocks (``` or ~~~). An unclosed fence runs to EOF.
local function fenced_ranges(s)
	local ranges, open_at, marker = {}, nil, nil
	for pos, line in s:gmatch("()([^\n]*)\n?") do
		local fence = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
		if fence then
			if not open_at then
				open_at, marker = pos, fence:sub(1, 1)
			elseif fence:sub(1, 1) == marker then
				ranges[#ranges + 1] = { open_at, pos + #line }
				open_at, marker = nil, nil
			end
		end
	end
	if open_at then
		ranges[#ranges + 1] = { open_at, #s }
	end
	return ranges
end

local function in_ranges(ranges, i)
	for _, r in ipairs(ranges) do
		if i >= r[1] and i <= r[2] then
			return true
		end
	end
	return false
end

---Earliest opener at a line start and outside a code fence.
---@return integer|nil start
local function find_trigger(s, from)
	local ranges = fenced_ranges(s)
	local best
	for _, trig in ipairs(TRIGGERS) do
		local init = from
		while true do
			local a = s:find(trig, init, true)
			if not a then
				break
			end
			if at_line_start(s, a) and not in_ranges(ranges, a) then
				if not best or a < best then
					best = a
				end
				break
			end
			init = a + 1
		end
	end
	return best
end

-- After "</parameter>": only whitespace, then the next structural token or EOF.
local function param_boundary_after(s, i)
	local j = skip_ws(s, i)
	return j > #s or starts_at(s, j, PARAM_OPEN) or starts_at(s, j, FUNC_CLOSE) or starts_at(s, j, TOOL_CLOSE)
end

-- After "</function>" (used only when "</parameter>" was dropped).
local function call_boundary_after(s, i)
	local j = skip_ws(s, i)
	return j > #s or starts_at(s, j, TOOL_CLOSE) or starts_at(s, j, TOOL_OPEN) or starts_at(s, j, FUNC_OPEN)
end

---Where does the value that starts at `from` end?
---A terminator only counts when it is structural, so code containing the tag
---text mid-line survives. Earliest structural terminator wins, which is also
---what recovers a dropped "</parameter>".
---@return integer|nil value_end  index of the first byte of the terminator
---@return integer|nil next_pos   where parsing resumes
local function scan_value(s, from)
	local best_pos, best_next
	local function consider(pos, nxt)
		if not best_pos or pos < best_pos then
			best_pos, best_next = pos, nxt
		end
	end

	local init = from
	while true do -- (1) the proper terminator
		local a, b = s:find(PARAM_CLOSE, init, true)
		if not a then
			break
		end
		if param_boundary_after(s, b + 1) then
			consider(a, b + 1)
			break
		end
		init = b + 1
	end

	init = from
	while true do -- (2) "</function>" on its own line: "</parameter>" was dropped
		local a, b = s:find(FUNC_CLOSE, init, true)
		if not a then
			break
		end
		if (a == from or s:sub(a - 1, a - 1) == "\n") and call_boundary_after(s, b + 1) then
			consider(a, a)
			break
		end
		init = b + 1
	end

	init = from
	while true do -- (3) next "<parameter=KEY>" at a line start: "</parameter>" was dropped
		local a = s:find(PARAM_OPEN, init, true)
		if not a then
			break
		end
		if s:sub(a - 1, a - 1) == "\n" and s:match("^<parameter=[^>\n]+>", a) then
			consider(a, a)
			break
		end
		init = a + 1
	end

	return best_pos, best_next
end

-- Strip exactly one newline at each end (the template's own), nothing else.
local function strip_wrapping_newline(v)
	v = v:gsub("^\r?\n", "", 1)
	v = v:gsub("\r?\n$", "", 1)
	return v
end

---@return table params, string[] order, integer next_pos, string how "closed"|"eof"|"garbage"
local function parse_params(s, i)
	local params, order = {}, {}
	while true do
		i = skip_ws(s, i)
		if i > #s then
			return params, order, i, "eof"
		end
		if starts_at(s, i, FUNC_CLOSE) then
			return params, order, i + #FUNC_CLOSE, "closed"
		end
		if starts_at(s, i, TOOL_CLOSE) then -- "</function>" dropped
			return params, order, i, "closed"
		end
		local key, after = s:match("^<parameter=([^>\n]+)>()", i)
		if not key then
			return params, order, i, "garbage"
		end
		local pos, nxt = scan_value(s, after)
		if not pos then
			return params, order, #s + 1, "eof" -- value never terminated: truncated
		end
		key = vim.trim(key)
		if params[key] == nil then
			order[#order + 1] = key
		end
		params[key] = strip_wrapping_newline(s:sub(after, pos - 1))
		i = nxt
	end
end

---Pull every complete call out of `text`.
---Incomplete or malformed calls are left in `content` and reported in `problems`;
---nothing half-parsed is ever returned as a call.
---@param text string
---@return { content: string, calls: { name: string, params: table<string,string>, order: string[] }[], problems: string[] }
function M.extract(text)
	local calls, pieces, problems = {}, {}, {}
	local pos = 1
	while true do
		local ts = find_trigger(text, pos)
		if not ts then
			pieces[#pieces + 1] = text:sub(pos)
			break
		end
		pieces[#pieces + 1] = text:sub(pos, ts - 1)

		local i = ts
		if starts_at(text, i, TOOL_OPEN) then
			i = skip_ws(text, i + #TOOL_OPEN)
		end
		local failed = false
		local got = 0
		while starts_at(text, i, FUNC_OPEN) do -- tolerate several functions in one wrapper
			local name, after = text:match("^<function=([^>\n]+)>()", i)
			if not name then
				problems[#problems + 1] = "function tag without '>'"
				failed = true
				break
			end
			local params, order, nxt, how = parse_params(text, after)
			if how ~= "closed" then
				problems[#problems + 1] = ("call to %s is %s"):format(
					vim.trim(name),
					how == "eof" and "truncated" or "malformed"
				)
				failed = true
				break
			end
			calls[#calls + 1] = { name = vim.trim(name), params = params, order = order }
			got = got + 1
			i = skip_ws(text, nxt)
		end
		if failed or got == 0 then
			if got == 0 and not failed then
				problems[#problems + 1] = "opener without a function"
			end
			pieces[#pieces + 1] = text:sub(ts) -- keep the raw text; do not guess
			break
		end
		if starts_at(text, i, TOOL_CLOSE) then
			i = i + #TOOL_CLOSE
		end
		pos = i
	end
	local kept = {}
	for idx, piece in ipairs(pieces) do
		piece = piece:gsub("%s+$", "")
		if idx > 1 then
			piece = piece:gsub("^%s+", "")
		end
		if piece ~= "" then
			kept[#kept + 1] = piece
		end
	end
	return { content = table.concat(kept, "\n\n"), calls = calls, problems = problems }
end

-- ---------------------------------------------------------------------------
-- Schema-driven coercion
-- ---------------------------------------------------------------------------

local function type_set(schema)
	local set = {}
	if type(schema) ~= "table" then
		return set
	end
	local t = schema.type
	if type(t) == "string" then
		set[t] = true
	elseif type(t) == "table" then
		for _, x in ipairs(t) do
			set[x] = true
		end
	end
	for _, key in ipairs({ "anyOf", "oneOf" }) do
		if type(schema[key]) == "table" then
			for _, sub in ipairs(schema[key]) do
				for k in pairs(type_set(sub)) do
					set[k] = true
				end
			end
		end
	end
	if next(set) == nil and schema.enum then
		set.string = true
	end
	return set
end

---Convert one raw string according to its JSON schema.
---Order: null > integer > number > boolean > object/array > string, like Qwen's
---own parser and vLLM, but a value that fits none of the declared non-string
---types is an error rather than a silent `false`/string.
---@return boolean ok, any value, string|nil err
function M.coerce(raw, schema)
	local t = type_set(schema)
	if next(t) == nil then
		return true, raw
	end
	local trimmed = vim.trim(raw)
	if t.null and trimmed:lower() == "null" then
		return true, nil
	end
	if t.integer and trimmed:match("^[+-]?%d+$") then
		local n = tonumber(trimmed)
		if n and math.abs(n) < 2 ^ 53 then
			return true, n -- LuaJIT numbers are doubles; vim.json.encode(10) is "10"
		end
	end
	if t.number and trimmed:match("^[+-]?%d*%.?%d+[eE]?[+-]?%d*$") then
		local n = tonumber(trimmed)
		if n then
			return true, n
		end
	end
	if t.boolean then
		local l = trimmed:lower()
		if l == "true" then
			return true, true
		elseif l == "false" then
			return true, false
		end
	end
	if (t.array and trimmed:sub(1, 1) == "[") or (t.object and trimmed:sub(1, 1) == "{") then
		local ok, v = pcall(vim.json.decode, trimmed, { luanil = { object = true, array = true } })
		if ok and type(v) == "table" then
			local is_list = vim.islist(v)
			if (t.array and is_list) or (t.object and not is_list) then
				return true, v
			end
		end
	end
	if t.string then
		return true, raw
	end
	return false, nil, ("value %q does not fit type %s"):format(raw:sub(1, 40), table.concat(vim.tbl_keys(t), "|"))
end

---Array-of-object parameters: the model sometimes writes the elements as sibling
---<parameter=oldText>/<parameter=newText> tags instead of one JSON array, so the
---array parameter itself comes out empty (or starting with a nested tag) and the
---element fields arrive as top-level parameters the tool does not declare.
---Fold those fields back into elements; a repeated field name starts the next
---element. Only fields the array's item schema declares are claimed.
local function repair_nested(call, schema)
	local props = (schema and schema.properties) or {}
	for _, key in ipairs(vim.deepcopy(call.order)) do
		local p = props[key]
		local raw = call.params[key]
		if p and raw and type_set(p).array and p.items and p.items.properties then
			local blank = raw:match("^%s*$") ~= nil
			local nested_first = raw:match("^%s*<parameter=") ~= nil
			if blank or nested_first then
				local item_props = p.items.properties
				local items, cur = {}, {}
				if nested_first then
					local ikey, rest = raw:match("^%s*<parameter=([^>\n]+)>()")
					cur[vim.trim(ikey)] = strip_wrapping_newline(raw:sub(rest))
				end
				local keep, seen = {}, false
				for _, k in ipairs(call.order) do
					if k == key then
						seen = true
						keep[#keep + 1] = k
					elseif seen and props[k] == nil and item_props[k] ~= nil then
						if cur[k] ~= nil then
							items[#items + 1] = cur
							cur = {}
						end
						cur[k] = call.params[k]
						call.params[k] = nil
					else
						keep[#keep + 1] = k
					end
				end
				if next(cur) ~= nil then
					items[#items + 1] = cur
				end
				if #items > 0 then
					for _, item in ipairs(items) do
						for ik, iv in pairs(item) do
							local ok, v = M.coerce(iv, item_props[ik])
							if ok then
								item[ik] = v -- (not `ok and v or iv`: v may be false)
							end
						end
					end
					call.params[key] = vim.json.encode(items) -- re-enter the normal coercion path
					call.order = keep
					call.repaired = true
				end
			end
		end
	end
end

---@param call { name: string, params: table<string,string>, order: string[] }
---@param schema table|nil JSON schema of the tool's `parameters`
---@return table args, string[] errors
function M.build_args(call, schema)
	repair_nested(call, schema)
	local props = (schema and schema.properties) or {}
	local args, errs = {}, {}
	for _, key in ipairs(call.order) do
		local ok, v, err = M.coerce(call.params[key], props[key])
		if ok then
			args[key] = v
		else
			errs[#errs + 1] = ("%s.%s: %s"):format(call.name, key, err)
		end
	end
	if next(args) == nil then
		args = vim.empty_dict() -- vim.json.encode({}) is "[]", which Ollama's arguments object rejects
	end
	return args, errs
end

---Text -> CodeCompanion tool-call entries.
---@param text string full assistant content
---@param schemas table<string, table> tool name -> `parameters` schema, for the tools offered this request
---@return table|nil calls, string content, string[] problems
function M.to_tool_calls(text, schemas)
	local r = M.extract(text)
	if #r.calls == 0 then
		return nil, text, r.problems
	end
	local out, problems = {}, vim.deepcopy(r.problems)
	for idx, call in ipairs(r.calls) do
		if schemas[call.name] == nil then
			problems[#problems + 1] = ("unknown tool %q"):format(call.name)
			return nil, text, problems -- all or nothing: never run half a turn
		end
		local args, errs = M.build_args(call, schemas[call.name])
		if #errs > 0 then
			vim.list_extend(problems, errs)
			return nil, text, problems
		end
		out[idx] = {
			_index = idx,
			id = ("call_xml_%x_%d"):format(vim.uv.hrtime() % 0xffffffff, idx),
			type = "function",
			["function"] = { name = call.name, arguments = args },
		}
	end
	return out, r.content, problems
end

-- ---------------------------------------------------------------------------
-- Streaming holdback
-- ---------------------------------------------------------------------------

local Stream = {}
Stream.__index = Stream

---@return table
function M.new_stream()
	return setmetatable({ buf = "", released = 0, triggered = false }, Stream)
end

-- How many trailing bytes might still turn into an opener?
local function holdback_len(tail)
	local trimmed = tail:gsub("%s+$", "")
	local ws = #tail - #trimmed
	local line_start = (trimmed:find("\n[^\n]*$") or 0) + 1
	local stripped = trimmed:sub(line_start):gsub("^%s+", "")
	if #stripped > 0 then
		for _, trig in ipairs(TRIGGERS) do
			if #stripped < #trig and trig:sub(1, #stripped) == stripped then
				local before = trimmed:sub(1, line_start - 1):gsub("%s+$", "")
				return #tail - #before
			end
		end
	end
	return ws
end

---Feed one content delta, get back the text that is safe to show now.
---Once an opener is seen, everything after it is withheld until finish().
---@param delta string
---@return string visible
function Stream:feed(delta)
	self.buf = self.buf .. delta
	if self.triggered then
		return ""
	end
	local ts = find_trigger(self.buf, self.released + 1)
	if ts then
		local visible = self.buf:sub(self.released + 1, ts - 1):gsub("%s+$", "")
		self.released = ts - 1
		self.triggered = true
		return visible
	end
	local tail = self.buf:sub(self.released + 1)
	local hold = holdback_len(tail)
	local visible = tail:sub(1, #tail - hold)
	self.released = self.released + #visible
	return visible
end

---@return string held_text  withheld text from the first opener on ("" if none)
---@return string flush       text that was merely held back and is safe to show
function Stream:finish()
	if self.triggered then
		return self.buf:sub(self.released + 1), ""
	end
	return "", (self.buf:sub(self.released + 1):gsub("%s+$", ""))
end

M._internal = { scan_value = scan_value, find_trigger = find_trigger, type_set = type_set }

return M
