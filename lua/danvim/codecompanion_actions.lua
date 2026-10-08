-- danvim.codecompanion_actions -- the CodeCompanion keybinding actions that are more
-- than a command: add the current file to the chat's context, pick a file to add,
-- clear the conversation. Bound in plugins/codecompanion.lua.
--
-- They act on the most recent chat (the one <leader>at toggles), opening it if it
-- is hidden and creating one if none exists, so each works from a cold start.
local M = {}

---The chat to act on, made visible. A new one when there is none yet.
---@return table|nil chat CodeCompanion.Chat
local function chat_to_use()
	local codecompanion = require("codecompanion")
	local chat = codecompanion.last_chat()
	if chat then
		if not chat.ui:is_visible() then
			chat.ui:open()
		end
		return chat
	end
	return codecompanion.chat()
end

---Add the file in the current buffer to the chat's context.
---
---Goes through the plugin's own context helper (the one prompt-library `context`
---entries use): a file that is open in a buffer is added as that buffer, so the
---unsaved text is what the model sees, and any other file is read from disk.
function M.add_current_file()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" or vim.bo.buftype ~= "" then
		return vim.notify("CodeCompanion: this buffer is not a file", vim.log.levels.WARN)
	end
	-- Resolved before the chat takes focus
	local chat = chat_to_use()
	if not chat then
		return
	end
	require("codecompanion.interactions.chat.slash_commands").context(chat, "file", { path = path })
	vim.notify(("CodeCompanion: added %s to the context"):format(vim.fn.fnamemodify(path, ":~:.")))
end

---Open the /file picker (snacks, in this config) and add what is chosen.
function M.add_file_picker()
	local chat = chat_to_use()
	if not chat then
		return
	end
	local slash_commands = require("codecompanion.config").interactions.chat.slash_commands
	require("codecompanion.interactions.chat.slash_commands").new():execute({
		label = "/file",
		config = slash_commands["file"],
		context = chat.buffer_context,
	}, chat)
end

---Clear the conversation: messages, context and tool state, keeping the chat window.
function M.clear()
	local chat = require("codecompanion").last_chat()
	if not chat then
		return vim.notify("CodeCompanion: there is no conversation to clear", vim.log.levels.INFO)
	end
	-- Clearing under a streaming response would leave it writing into the new buffer
	if chat.current_request then
		chat:stop()
	end
	chat:clear()
	vim.notify("CodeCompanion: conversation cleared")
end

return M
