-- Handler-level tests for danvim.codecompanion_qwen_adapter.
-- run: nvim --headless -u NONE -l tests/qwen_adapter_test.lua
--
-- CodeCompanion's modules are stubbed (the real ones need the plugin on the
-- runtimepath), but the stubs copy the stock ollama adapter's chat_output
-- logic, and the test reproduces the one property that bit a previous version:
-- http.lua runs form_tools on vim.deepcopy(adapter), while the chat passes its
-- ORIGINAL adapter to chat_output. State stored on `self` in form_tools is lost.
--
-- The end-to-end check that this file cannot do is a real chat against a real
-- model; see the notes in the commit that added it.
local here = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
package.path = here .. "../lua/?.lua;" .. package.path

local logged = {}
package.preload["codecompanion.utils.log"] = function()
	local log = {}
	function log:info(fmt, ...)
		logged[#logged + 1] = "INFO " .. fmt:format(...)
	end
	function log:warn(fmt, ...)
		logged[#logged + 1] = "WARN " .. fmt:format(...)
	end
	return log
end
package.preload["codecompanion.adapters.utils"] = function()
	return {
		clean_streamed_data = function(d)
			return d
		end,
		-- adapters/utils/init.lua
		pairing_id = function(tool_call)
			return tool_call.call_id or tool_call.id
		end,
	}
end
-- A copy of the stock ollama handlers' relevant logic (adapters/http/ollama/init.lua)
package.preload["codecompanion.adapters.http.ollama"] = function()
	return {
		handlers = {
			tools = {
				-- adapters/http/ollama/init.lua, verbatim: no tools.call_id
				output_response = function(self, tool_call, output)
					return {
						role = self.roles and self.roles.tool or "tool",
						tool_name = tool_call["function"]["name"],
						content = output,
						opts = { visible = false },
					}
				end,
			},
			-- The real one (openai.handlers.form_tools) returns { tools = { {type=, function=}, ... } }
			form_tools = function(_, tools)
				return tools
			end,
			chat_output = function(self, data, tools)
				if not data or data == "" then
					return nil
				end
				local body = type(data) == "table" and data.body or data
				local ok, json = pcall(vim.json.decode, body, { luanil = { object = true } })
				if not ok or not json.message then
					return nil
				end
				local message = json.message
				if self.opts.tools and tools then
					if message.tool_calls and #message.tool_calls > 0 then
						for i, tool in ipairs(message.tool_calls) do
							table.insert(tools, {
								_index = tool.index and tonumber(tool.index) or i,
								id = tool.id or ("call_" .. i),
								type = tool.type or "function",
								["function"] = {
									name = tool["function"]["name"],
									arguments = tool["function"]["arguments"] or "",
								},
							})
						end
					end
				end
				return { status = "success", output = { role = message.role, content = message.content } }
			end,
		},
	}
end

local A = require("danvim.codecompanion_qwen_adapter")

local pass, fail = 0, 0
local function check(name, cond, detail)
	if cond then
		pass = pass + 1
	else
		fail = fail + 1
		print(("FAIL %s%s"):format(name, detail and (": " .. tostring(detail)) or ""))
	end
end

local TOOLS_OFFERED = {
	tools = {
		{
			type = "function",
			["function"] = {
				name = "read_file",
				parameters = {
					type = "object",
					properties = {
						filepath = { type = "string" },
						start_line = { type = "integer" },
					},
				},
			},
		},
		{
			type = "function",
			["function"] = {
				name = "edit_file",
				parameters = {
					type = "object",
					properties = {
						filepath = { type = "string" },
						oldText = { type = "string" },
						newText = { type = "string" },
						replaceAll = { type = "boolean" },
					},
				},
			},
		},
	},
}

---Run one request the way Chat:_submit_http does.
---@param chunks string[] message.content deltas
---@param opts? { done_reason?: string, native?: table[], offer?: boolean, final_content?: string }
---@return string shown, table[] tools
local function run(chunks, opts)
	opts = opts or {}
	local adapter = { opts = { tools = true } }
	-- http.lua: prepare_adapter() -> form_tools runs on a COPY of the adapter
	local request_copy = vim.deepcopy(adapter)
	if opts.offer ~= false then
		A.form_tools(request_copy, TOOLS_OFFERED)
	else
		A.form_tools(request_copy, { tools = {} })
	end

	local tools, shown = {}, {}
	local function feed(content, extra)
		local msg = { role = "assistant", content = content }
		for k, v in pairs(extra or {}) do
			msg[k] = v
		end
		local body = vim.json.encode(vim.tbl_extend("force", { message = msg, done = false }, opts.chunk_extra or {}))
		return A.chat_output(adapter, { body = body }, tools)
	end
	for _, c in ipairs(chunks) do
		local r = feed(c, opts.native and { tool_calls = opts.native } or nil)
		if r and r.output and r.output.content then
			shown[#shown + 1] = r.output.content
		end
		opts.native = nil -- native calls arrive once
	end
	local final = vim.json.encode({
		message = { role = "assistant", content = "" },
		done = true,
		done_reason = opts.done_reason or "stop",
	})
	local r = A.chat_output(adapter, { body = final }, tools)
	if r and r.output and r.output.content then
		shown[#shown + 1] = r.output.content
	end
	return table.concat(shown), tools
end

local function split(s, n)
	local out = {}
	for i = 1, #s, n do
		out[#out + 1] = s:sub(i, i + n - 1)
	end
	return out
end

-- The shape from ollama#18530: preamble, then <function=...> with NO <tool_call>
-- opener, ending in a stray </tool_call>.
local LEAK = "I'll read the file first, then rename the function.\n\n"
	.. "<function=read_file>\n<parameter=filepath>\n/tmp/a.lua\n</parameter>\n<parameter=start_line>\n3\n</parameter>\n</function>\n</tool_call>"

for _, n in ipairs({ 1, 3, 7, 16, #LEAK }) do
	logged = {}
	local shown, tools = run(split(LEAK, n))
	check(("leak recovered at chunk size %d"):format(n), #tools == 1, "tools=" .. #tools)
	local call = tools[1]
	check(
		("  name/args chunk %d"):format(n),
		call
			and call["function"].name == "read_file"
			and call["function"].arguments.filepath == "/tmp/a.lua"
			and call["function"].arguments.start_line == 3,
		call and vim.inspect(call["function"])
	)
	check(
		("  XML hidden chunk %d"):format(n),
		not shown:find("<function", 1, true) and not shown:find("</tool_call>", 1, true),
		shown
	)
	check(("  prose kept chunk %d"):format(n), shown:find("I'll read the file first", 1, true) ~= nil, shown)
	check(("  call shape chunk %d"):format(n), call and call.type == "function" and call.id ~= nil and call._index == 1)
end
check("recovery logged", (logged[1] or ""):find("recovered 1 tool call", 1, true) ~= nil, logged[1])

-- Same, with a <tool_call> opener present but Ollama still failing to parse
do
	local shown, tools = run(
		split("<tool_call>\n<function=read_file>\n<parameter=filepath>\n/x\n</parameter>\n</function>\n</tool_call>", 5)
	)
	check("wrapped call recovered", #tools == 1 and tools[1]["function"].arguments.filepath == "/x")
	check("wrapped call hidden", shown == "", shown)
end

-- Two calls in one message
do
	local text = "<function=read_file>\n<parameter=filepath>\n/a\n</parameter>\n</function>\n"
		.. "<function=edit_file>\n<parameter=filepath>\n/a\n</parameter>\n<parameter=oldText>\nx\n</parameter>\n<parameter=newText>\ny\n</parameter>\n<parameter=replaceAll>\ntrue\n</parameter>\n</function>"
	local _, tools = run(split(text, 9))
	check("two calls", #tools == 2 and tools[2]["function"].arguments.replaceAll == true and tools[2]._index == 2)
end

-- Dropped </parameter> before </function>
do
	local _, tools = run({ "<function=read_file>\n<parameter=filepath>\n/z\n</function>" })
	check("dropped closer recovered", #tools == 1 and tools[1]["function"].arguments.filepath == "/z")
end

-- Ollama parsed the call itself: stay out of the way, content untouched
do
	local native = {
		{ id = "c1", type = "function", ["function"] = { name = "read_file", arguments = { filepath = "/n" } } },
	}
	local shown, tools = run({ "Reading it now." }, { native = native })
	check(
		"native call untouched",
		#tools == 1 and tools[1].id == "c1" and tools[1]["function"].arguments.filepath == "/n"
	)
	check("native content shown", shown == "Reading it now.", shown)
end

-- Plain prose, including angle brackets, is shown whole and nothing is executed
do
	local prose = "Use `a < b` and <div> tags; the <function=x> mention is inline."
	local shown, tools = run(split(prose, 4))
	check("prose untouched", shown == prose, shown)
	check("prose no calls", #tools == 0)
end

-- Truncated generation never executes
do
	local _, tools = run(split(LEAK, 8), { done_reason = "length" })
	check("length limit: nothing executed", #tools == 0)
end

-- Unknown tool: left as text, nothing executed
do
	local shown, tools = run({ "<function=rm_rf>\n<parameter=path>\n/\n</parameter>\n</function>" })
	check("unknown tool not executed", #tools == 0)
	check("unknown tool stays visible", shown:find("rm_rf", 1, true) ~= nil, shown)
end

-- No tools offered on this request: stock behaviour
do
	local shown, tools = run({ LEAK }, { offer = false })
	check("no tools offered: no recovery", #tools == 0)
	check("no tools offered: text shown", shown:find("<function=read_file>", 1, true) ~= nil, shown)
end

-- The result of a tool call must name the call it answers, or Chat:_orphaned_tool_calls
-- never pairs them and fabricates a "did not complete" result per call per turn.
do
	local call = { id = "call_abc", type = "function", ["function"] = { name = "read_file", arguments = {} } }
	local msg = A.output_response({ roles = {} }, call, "file contents")
	check(
		"result keeps role/content",
		msg.role == "tool" and msg.content == "file contents" and msg.opts.visible == false
	)
	check("result carries call_id", msg.tools and msg.tools.call_id == "call_abc", vim.inspect(msg.tools))
	check("result carries name", msg.tools and msg.tools.name == "read_file")
	-- and a call id minted by the XML recovery pairs the same way
	local _, tools = run({ "<function=read_file>\n<parameter=filepath>\n/a\n</parameter>\n</function>" })
	local m2 = A.output_response({ roles = {} }, tools[1], "ok")
	check("recovered call pairs with its result", m2.tools.call_id == tools[1].id and tools[1].id ~= nil)
end

print(("passed %d, failed %d"):format(pass, fail))
vim.cmd(fail == 0 and "qa!" or "cq")
