-- danvim.codecompanion_xml_tools -- recover the tool calls ollama drops.
--
-- THE BUG THIS EXISTS FOR
--
-- qwen3-coder emits tool calls in its own XML syntax:
--
--   <tool_call>
--   <function=grep_search>
--   <parameter=query>
--   colorscheme
--   </parameter>
--   </function>
--   </tool_call>
--
-- Ollama ships a parser for that shape (`PARSER qwen3-coder` in the modelfile)
-- and intermittently fails on it -- ollama#17276, open, a duplicate of #14834,
-- unfixed as of July 2026. When it fails the request still returns 200, but the
-- call arrives as ordinary message content with `tool_calls` empty, and the
-- opening <tool_call> is missing from the text: the parser consumed it, gave up
-- inside, and flushed the rest as prose.
--
-- CodeCompanion continues a turn only when the response carries tool calls
-- (Chat:done runs them, and ToolsFinished -> auto_submit_success fires the next
-- request -- that loop IS the agent). A dropped call therefore ends the turn
-- mid-task, and pressing <CR> only helps because an empty submit re-rolls the
-- sampling. Measured on this config: about 6 in 21 requests at 7 tools, none in
-- 22 at 5. Keeping default_tools at five (see plugins/codecompanion.lua) avoids
-- most of it; this catches the rest, and anything a bigger context brings back.
--
-- block/goose hit the same wall and fixed it the same way, client-side, in
-- goose#6882: when tool_calls is empty, parse the XML out of the content
-- yourself and dispatch it.
--
-- WHERE IT HOOKS
--
-- The `CodeCompanionChatDone` event, which Chat:done fires only on the path
-- where no tool calls were found -- exactly the failure case, so this never
-- races a healthy turn. One cosmetic consequence: ready_for_input() has already
-- drawn the next `## Me` header by then, so recovered tool output lands under
-- it rather than under the LLM's. The message list, which is what the model
-- actually sees, is unaffected.
--
-- API NOTE: written against codecompanion 19.x. A tool call is
-- `{ id, type = "function", ["function"] = { name, arguments } }`, and
-- Tools:execute takes `arguments` as a table or a JSON string
-- (_resolve_and_prepare_tool decodes strings, so a table skips a round trip).

local M = {}

---Pull qwen3-coder's XML tool calls out of a message.
---
---Deliberately tolerant about the wrapper: the failure being recovered from is
---one where ollama already ate the opening <tool_call>, so only the
---<function=...> blocks are matched, and the leftover tags are stripped after.
---@param text string
---@return table[]|nil calls, string|nil remainder The message minus the calls
function M.parse(text)
  if not text:find("<function=", 1, true) then
    return nil
  end

  local calls = {}
  for name, body in text:gmatch("<function=([%w_%-]+)>(.-)</function>") do
    local args = {}
    for key, value in body:gmatch("<parameter=([%w_%-]+)>(.-)</parameter>") do
      -- The model puts the value on its own lines. Strip exactly the one
      -- newline either side and nothing more: these values carry code, and
      -- trimming its indentation would corrupt an edit.
      args[key] = (value:gsub("^\n", ""):gsub("\n$", ""))
    end
    table.insert(calls, {
      id = ("xml_%d_%d"):format(#calls + 1, math.random(100000)),
      type = "function",
      ["function"] = { name = name, arguments = args },
    })
  end

  if #calls == 0 then
    return nil
  end

  local remainder = text
    :gsub("<function=[%w_%-]+>.-</function>", "")
    :gsub("</?tool_call>", "")
  return calls, vim.trim(remainder)
end

---@param chat table
---@param calls table[]
---@return boolean
local function all_available(chat, calls)
  for _, call in ipairs(calls) do
    if not chat.tool_registry.in_use[call["function"].name] then
      return false
    end
  end
  return true
end

---@param bufnr integer
---@return nil
local function recover(bufnr)
  local chat = require("codecompanion.interactions.chat").buf_get_chat(bufnr)
  if not chat then
    return
  end

  local llm = require("codecompanion.config").constants.LLM_ROLE
  local message
  for i = #chat.messages, 1, -1 do
    if chat.messages[i].role == llm then
      message = chat.messages[i]
      break
    end
  end
  if not message or type(message.content) ~= "string" then
    return
  end

  local calls, remainder = M.parse(message.content)
  if not calls then
    return
  end

  -- Only dispatch calls to tools this chat actually offered. Without this, a
  -- chat that merely *discusses* the syntax -- debugging this very bug, say --
  -- would have its own transcript executed.
  if not all_available(chat, calls) then
    return vim.notify(
      "Ignoring XML tool calls naming tools this chat does not have",
      vim.log.levels.WARN
    )
  end

  -- Strip the raw XML out of the transcript. Two reasons: the model would
  -- otherwise see its own leaked syntax in the history and is that much more
  -- likely to repeat it, and this is what stops a recovery from being parsed a
  -- second time on the next pass through this handler.
  message.content = remainder

  chat:add_message({ role = llm, tool_calls = calls }, { visible = false })
  vim.notify(("Recovered %d unparsed tool call(s)"):format(#calls))
  chat.tools:execute(chat, calls)
end

---@return nil
function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionChatDone",
    group = vim.api.nvim_create_augroup("danvim_codecompanion_xml_tools", { clear = true }),
    callback = function(event)
      local bufnr = event.data and event.data.bufnr
      if not bufnr then
        return
      end
      -- Scheduled so the recovery does not run inside Chat:done's own stack,
      -- which is still finishing its buffer writes when the event fires.
      vim.schedule(function()
        local ok, err = pcall(recover, bufnr)
        if not ok then
          require("codecompanion.utils.log"):error("[xml_tools] Recovery failed: %s", err)
        end
      end)
    end,
  })
end

return M
