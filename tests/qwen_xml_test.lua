-- run: nvim --headless -l tests/qwen_xml_test.lua
-- resolve lua/ relative to this file, so it runs from any checkout
local here = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
package.path = here .. "../lua/?.lua;" .. package.path
local X = require("danvim.qwen_xml")

local pass, fail = 0, 0
local function check(name, cond, detail)
	if cond then
		pass = pass + 1
	else
		fail = fail + 1
		print(("FAIL %s %s"):format(name, detail and vim.inspect(detail) or ""))
	end
end

-- The five tools' real schemas (shapes copied from CodeCompanion 19.27.0 builtin tools)
local S = {
	grep_search = {
		type = "object",
		properties = {
			query = { type = "string" },
			is_regexp = { type = "boolean" },
			include_pattern = { type = "string" },
		},
		required = { "query" },
	},
	read_file = {
		type = "object",
		properties = {
			filepath = { type = "string" },
			start_line_number_base_zero = { type = "integer" },
			end_line_number_base_zero = { type = "integer" },
		},
		required = { "filepath" },
	},
	run_command = {
		type = "object",
		properties = { cmd = { type = "string" }, flag = { type = { "string", "null" } } },
		required = { "cmd" },
	},
	skill = { type = "object", properties = { name = { type = "string" } }, required = { "name" } },
	insert_edit_into_file = {
		type = "object",
		properties = {
			filepath = { type = "string" },
			edits = {
				type = "array",
				items = {
					type = "object",
					properties = {
						oldText = { type = "string" },
						newText = { type = "string" },
						replaceAll = { type = "boolean" },
					},
					required = { "oldText", "newText", "replaceAll" },
				},
			},
			mode = { type = "string", enum = { "append", "overwrite" } },
			explanation = { type = "string" },
		},
		required = { "filepath", "edits", "explanation", "mode" },
	},
	ping = { type = "object", properties = {} },
	["mcp.server:do-thing"] = { type = "object", properties = { x = { type = "integer" } } },
}

local function conv(text)
	return X.to_tool_calls(text, S)
end
local function args_of(text, i)
	local calls, content, problems = conv(text)
	return calls and calls[i or 1]["function"].arguments, content, problems, calls
end

-- 1 canonical
do
	local a, c = args_of(
		"<tool_call>\n<function=grep_search>\n<parameter=query>\ncolorscheme\n</parameter>\n</function>\n</tool_call>"
	)
	check("1 canonical", a and a.query == "colorscheme" and c == "", { a, c })
end
-- 2 bare opener + stray closer, prose before (ollama#18530)
do
	local a, c = args_of(
		"I will search.\n\n<function=grep_search>\n<parameter=query>\nfoo\n</parameter>\n</function>\n</tool_call>"
	)
	check("2 bare opener", a and a.query == "foo" and c == "I will search.", { a, c })
end
-- 3 literal </parameter> mid-value survives
do
	local a = args_of(
		'<function=insert_edit_into_file>\n<parameter=filepath>\n/a\n</parameter>\n<parameter=edits>\n[{"oldText":"x","newText":"let s = \\"</parameter> oops\\"","replaceAll":false}]\n</parameter>\n<parameter=mode>\nappend\n</parameter>\n<parameter=explanation>\ne\n</parameter>\n</function>'
	)
	check("3a literal close tag inside JSON value", a and a.edits[1].newText == 'let s = "</parameter> oops"', a)
	local b = args_of(
		'<function=grep_search>\n<parameter=query>\nlet s = "</parameter> oops";\nreturn s\n</parameter>\n</function>'
	)
	check("3b literal close tag inside plain value", b and b.query == 'let s = "</parameter> oops";\nreturn s', b)
end
-- 4 missing final </parameter> before </function>
do
	local a = args_of("<function=read_file>\n<parameter=filepath>\n/a/b.lua\n</function>\n</tool_call>")
	check("4 dropped </parameter> before </function>", a and a.filepath == "/a/b.lua", a)
end
-- 5 dropped </parameter> before next <parameter=
do
	local a = args_of(
		"<function=read_file>\n<parameter=filepath>\n/a/b.lua\n<parameter=start_line_number_base_zero>\n5\n</parameter>\n</function>"
	)
	check(
		"5 dropped </parameter> before next param",
		a and a.filepath == "/a/b.lua" and a.start_line_number_base_zero == 5,
		a
	)
end
-- 6 nested array-of-object shape (ollama#18563 tsnowlan)
do
	local a, _, _, calls = args_of(
		"<tool_call>\n<function=insert_edit_into_file>\n<parameter=filepath>\n/a.lua\n</parameter>\n<parameter=edits>\n<parameter=oldText>\nold\n</parameter>\n<parameter=newText>\nnew\n</parameter>\n<parameter=replaceAll>\nfalse\n</parameter>\n<parameter=mode>\nappend\n</parameter>\n<parameter=explanation>\nx\n</parameter>\n</function>\n</tool_call>"
	)
	check(
		"6 nested edits repaired",
		a
			and #a.edits == 1
			and a.edits[1].oldText == "old"
			and a.edits[1].newText == "new"
			and a.edits[1].replaceAll == false,
		a
	)
	check("6b stray element keys removed from top level", a and a.oldText == nil and a.newText == nil, a)
end
-- 7 JSON array value
do
	local a = args_of(
		'<function=insert_edit_into_file>\n<parameter=edits>\n[{"oldText":"a","newText":"b","replaceAll":false}]\n</parameter>\n</function>'
	)
	check(
		"7 JSON array decoded",
		a and vim.islist(a.edits) and a.edits[1].oldText == "a" and a.edits[1].replaceAll == false,
		a
	)
end
-- 8 integer / boolean coercion, invalid integer rejects the call
do
	local a = args_of(
		"<function=read_file>\n<parameter=filepath>\n/a.lua\n</parameter>\n<parameter=start_line_number_base_zero>\n10\n</parameter>\n</function>"
	)
	check("8a integer", a and a.start_line_number_base_zero == 10, a)
	local b = args_of(
		"<function=grep_search>\n<parameter=query>\nq\n</parameter>\n<parameter=is_regexp>\nTrue\n</parameter>\n</function>"
	)
	check("8b boolean", b and b.is_regexp == true, b)
	local calls, _, problems = conv(
		"<function=read_file>\n<parameter=filepath>\n/a\n</parameter>\n<parameter=start_line_number_base_zero>\nabc\n</parameter>\n</function>"
	)
	check("8c bad integer rejects", calls == nil and #problems > 0, problems)
end
-- 9 string|null
do
	local a = args_of(
		"<function=run_command>\n<parameter=cmd>\nls\n</parameter>\n<parameter=flag>\nnull\n</parameter>\n</function>"
	)
	check("9a null omitted", a and a.cmd == "ls" and a.flag == nil, a)
	local b = args_of(
		"<function=run_command>\n<parameter=cmd>\nls\n</parameter>\n<parameter=flag>\ntesting\n</parameter>\n</function>"
	)
	check("9b string branch", b and b.flag == "testing", b)
end
-- 10 CRLF
do
	local a = args_of("<function=grep_search>\r\n<parameter=query>\r\nfoo\r\n</parameter>\r\n</function>")
	check("10 CRLF", a and a.query == "foo", a)
end
-- 11 dotted/colon name
do
	local a, _, _, calls = args_of("<function=mcp.server:do-thing>\n<parameter=x>\n1\n</parameter>\n</function>")
	check("11 odd tool name", a and a.x == 1 and calls[1]["function"].name == "mcp.server:do-thing", calls)
end
-- 12 truncated -> no call, content preserved
do
	local calls, content, problems = conv("Working on it.\n\n<function=grep_search>\n<parameter=query>\nfoo")
	check(
		"12 truncated",
		calls == nil and content:find("<function=grep_search>", 1, true) and #problems > 0,
		{ content, problems }
	)
end
-- 13 fenced mention
do
	local calls =
		conv("Use it like:\n```xml\n<function=grep_search>\n<parameter=query>\nfoo\n</parameter>\n</function>\n```")
	check("13 fenced mention ignored", calls == nil)
	local calls2 = conv(
		"Use it like:\n~~~\n<tool_call>\n<function=grep_search>\n<parameter=query>\nfoo\n</parameter>\n</function>\n</tool_call>\n~~~\nthen run."
	)
	check("13b tilde fence ignored", calls2 == nil)
end
-- 14 inline mention mid-line
do
	local calls = conv("The format is <function=grep_search><parameter=query>x</parameter></function> as documented.")
	check("14 inline mention ignored", calls == nil)
end
-- 15 empty args -> {} not []
do
	local a = args_of("<function=ping>\n</function>")
	check("15 empty args encode as object", a and vim.json.encode(a) == "{}", a and vim.json.encode(a))
end
-- 16 whitespace exactness
do
	local a = args_of("<function=run_command>\n<parameter=cmd>\n  indented\n    more\n\n</parameter>\n</function>")
	check("16 indentation + one extra newline kept", a and a.cmd == "  indented\n    more\n", a)
end
-- 17 two calls (one wrapper each) and two functions in one wrapper
do
	local calls = conv(
		"Plan.\n\n<tool_call>\n<function=grep_search>\n<parameter=query>\na\n</parameter>\n</function>\n</tool_call>\n<tool_call>\n<function=read_file>\n<parameter=filepath>\n/b\n</parameter>\n</function>\n</tool_call>"
	)
	check("17a two wrappers", calls and #calls == 2 and calls[2]["function"].name == "read_file", calls)
	local calls2 = conv(
		"<tool_call>\n<function=grep_search>\n<parameter=query>\na\n</parameter>\n</function>\n<function=read_file>\n<parameter=filepath>\n/b\n</parameter>\n</function>\n</tool_call>"
	)
	check("17b two functions in one wrapper", calls2 and #calls2 == 2, calls2)
	local calls3 = conv(
		"<function=grep_search>\n<parameter=query>\na\n</parameter>\n</function>\n</tool_call>\n<function=read_file>\n<parameter=filepath>\n/b\n</parameter>\n</function>\n</tool_call>"
	)
	check("17c two bare calls", calls3 and #calls3 == 2, calls3)
end
-- 18 unknown tool -> all-or-nothing
do
	local calls, _, problems =
		conv("<function=grep_search>\n<parameter=query>\na\n</parameter>\n</function>\n<function=nope>\n</function>")
	check("18 unknown tool rejects whole turn", calls == nil and problems[#problems]:find("unknown tool"), problems)
end
-- 19 prose after the call is kept as content
do
	local a, c = args_of("<function=grep_search>\n<parameter=query>\na\n</parameter>\n</function>\n</tool_call>\nDone.")
	check("19 trailing prose kept", a and c == "Done.", c)
end
-- 20 missing both </parameter> and </tool_call>
do
	local a = args_of("<function=grep_search>\n<parameter=query>\nfoo\n</function>")
	check("20 dropped </parameter> and </tool_call>", a and a.query == "foo", a)
end
-- 21 value that itself contains a closing-looking line (documented limitation)
do
	local a = args_of(
		"<function=grep_search>\n<parameter=query>\nline\n</parameter>\n</function>\nmore\n</parameter>\n</function>"
	)
	check("21 first structural terminator wins (known limitation)", a and a.query == "line", a)
end
-- 22 big value, tag text inside code with newline-leading </function> but followed by code
do
	local code = "function f()\n  return 1\n</function>\nlocal x = 2"
	local a = args_of(
		"<function=insert_edit_into_file>\n<parameter=edits>\n"
			.. vim.json.encode({ { oldText = "a", newText = code, replaceAll = false } })
			.. "\n</parameter>\n</function>"
	)
	check("22 JSON-escaped code with </function>", a and a.edits[1].newText == code, a)
	local b = args_of("<function=grep_search>\n<parameter=query>\n" .. code .. "\n</parameter>\n</function>")
	check("22b raw value with </function> at line start followed by code", b and b.query == code, b)
end

-- ----------------------------------------------------------------------------
-- Streaming holdback: any chunking must yield the same visible text + raw tail
-- ----------------------------------------------------------------------------
local function run_stream(chunks)
	local st = X.new_stream()
	local shown = {}
	for _, ch in ipairs(chunks) do
		shown[#shown + 1] = st:feed(ch)
	end
	local raw, flush = st:finish()
	return table.concat(shown) .. flush, raw
end

local function split_chars(s, n)
	local out = {}
	for i = 1, #s, n do
		out[#out + 1] = s:sub(i, i + n - 1)
	end
	return out
end

local msg =
	"I will first look.\n\n<function=grep_search>\n<parameter=query>\nfoo\n</parameter>\n</function>\n</tool_call>"
for _, n in ipairs({ 1, 2, 3, 5, 7, 11, #msg }) do
	local shown, raw = run_stream(split_chars(msg, n))
	check(("23 stream chunk=%d visible"):format(n), shown == "I will first look.", shown)
	check(
		("23 stream chunk=%d raw"):format(n),
		raw:sub(1, 10) == "<function=" and raw:find("</tool_call>", 1, true),
		raw
	)
end
local msg2 =
	"Plan:\n<tool_call>\n<function=grep_search>\n<parameter=query>\nfoo\n</parameter>\n</function>\n</tool_call>"
for _, n in ipairs({ 1, 4, 9 }) do
	local shown, raw = run_stream(split_chars(msg2, n))
	check(
		("24 wrapped stream chunk=%d"):format(n),
		shown == "Plan:" and raw:sub(1, 11) == "<tool_call>",
		{ shown, raw }
	)
end
-- plain prose with angle brackets never gets stuck
local prose = "Use a < b and <div>x</div>\n<b>bold</b> and `<function=x>` inline.\n<fun"
for _, n in ipairs({ 1, 3, 100 }) do
	local shown, raw = run_stream(split_chars(prose, n))
	check(("25 prose stream chunk=%d fully flushed"):format(n), raw == "" and shown == prose, { shown, raw })
end
-- the partial "<" at the very end is flushed, not lost
do
	local shown, raw = run_stream({ "a <" })
	check("26 trailing '<' flushed", shown == "a <" and raw == "")
	local shown2, raw2 = run_stream({ "ok\n\n<" })
	check("26b line-start '<' flushed at finish", shown2 == "ok\n\n<" and raw2 == "", { shown2, raw2 })
end
-- end-to-end: stream -> extract
do
	local st = X.new_stream()
	local shown = {}
	for _, ch in ipairs(split_chars(msg, 6)) do
		shown[#shown + 1] = st:feed(ch)
	end
	local raw = st:finish()
	local calls, content = X.to_tool_calls(raw, S)
	check(
		"27 e2e",
		calls and calls[1]["function"].arguments.query == "foo" and table.concat(shown) == "I will first look.",
		{ shown, calls }
	)
end

print(("passed %d, failed %d"):format(pass, fail))
vim.cmd(fail == 0 and "qa!" or "cq")
