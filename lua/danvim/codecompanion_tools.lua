-- danvim.codecompanion_tools -- the tool prompt and edit tool, shaped for Qwen3-Coder.
--
-- Both exist because of how Ollama parses Qwen3-Coder's XML tool calls (see
-- danvim.qwen_xml for the full story):
--
--   * Ollama's parser only recognises a call that starts with the literal
--     `<tool_call>` token (ollama#18530), and the model skips that token after
--     a sentence of preamble. CodeCompanion's stock tool prompt asks for exactly
--     that preamble ("If you say that you will take an action, then go ahead and
--     use the tool"), and tells the model to "output valid JSON", which is not
--     the format Qwen3-Coder emits. `system_prompt` below drops both and asks for
--     the call with nothing around it.
--
--   * insert_edit_into_file takes `edits: [{oldText, newText, replaceAll}]`. An
--     array of objects is written by the model as sibling `<parameter=...>` tags
--     with the outer parameter never closed, and Ollama's strict XML parse then
--     throws the whole generation away (ollama#18563) -- unlike a dropped opener,
--     nothing on the client can recover that. `edit_file` takes one edit per call
--     with flat parameters, so there is no array to get wrong, and its schema is
--     a fraction of the size (the stock one is ~10 KB, ~2.5k tokens of every
--     request).
local M = {}

---The tools system prompt: CodeCompanion's stock text with the JSON and
---announce-then-act lines replaced, and the edit tool renamed.
---@param _ { ctx: table, tools: string[] }
---@return string
function M.system_prompt(_)
	return [[<instructions>
You are a highly sophisticated automated coding agent with expert-level knowledge across many different programming languages and frameworks.
The user will ask a question, or ask you to perform a task, and it may require lots of research to answer correctly. There is a selection of tools that let you perform actions or retrieve helpful context to answer the user's question.
You will be given some context and attachments along with the user prompt. You can use them if they are relevant to the task, and ignore them if not.
If you can infer the project type (languages, frameworks, and libraries) from the user's query or the context that you have, make sure to keep them in mind when making changes.
If the user wants you to implement a feature and they have not specified the files to edit, first break down the user's request into smaller concepts and think about the kinds of files you need to grasp each concept.
If you aren't sure which tool is relevant, you can call multiple tools. You can call tools repeatedly to take actions or gather as much context as needed until you have completed the task fully. Don't give up unless you are sure the request cannot be fulfilled with the tools you have. It's YOUR RESPONSIBILITY to make sure that you have done all you can to collect necessary context.
Don't make assumptions about the situation - gather context first, then perform the task or answer the question.
Think creatively and explore the workspace in order to make a complete fix.
Don't repeat yourself after a tool call, pick up where you left off.
NEVER print out a codeblock with a terminal command to run unless the user asked for it.
You don't need to read a file if it's already provided in context.
</instructions>
<toolUseInstructions>
When using a tool, follow its parameter schema very carefully and make sure to include ALL required parameters.
To call a tool, emit the tool call immediately and nothing else: no sentence before it and none after it. Explain what you did only after the tool result has come back.
Never announce an action instead of taking it. If an action needs a tool, call the tool; there is no need to ask permission.
If a tool exists to do a task, use the tool instead of asking the user to manually take an action.
Never use a tool that does not exist. Use tools using the proper procedure, DO NOT write out a code block with the tool inputs.
Never say the name of a tool to a user. For example, instead of saying that you'll use the edit_file tool, say "I'll edit the file".
For maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.
When invoking a tool that takes a file path, always use the file path you have been given by the user or by the output of a tool.
</toolUseInstructions>
<outputFormatting>
Use proper Markdown formatting in your answers. When referring to a filename or symbol in the user's workspace, wrap it in backticks.
Any code block examples must be wrapped in four backticks with the programming language.
<example>
````languageId
// Your code here
````
</example>
The languageId must be the correct identifier for the programming language, e.g. python, javascript, lua, etc.
If you are providing code changes, use the edit_file tool (if available to you) to make the changes directly instead of printing out a code block with the changes.
</outputFormatting>]]
end

---The flat, one-edit-per-call edit tool. Everything below the schema (matching,
---diff review, writing, buffer vs file handling, approvals) is the stock
---insert_edit_into_file; this only changes the shape the model has to produce.
---
---Called by CodeCompanion when a chat is opened (the tool config's `callback`),
---so the plugin is on the runtimepath by then.
---@return table
function M.edit_file()
	local stock = require("codecompanion.interactions.chat.tools.builtin.insert_edit_into_file")

	return vim.tbl_extend("force", {}, stock, {
		name = "edit_file",
		cmds = {
			---@param self table CodeCompanion.Tools
			---@param args { filepath: string, oldText: string, newText: string, replaceAll?: boolean }
			---@param opts table
			function(self, args, opts)
				return stock.cmds[1](self, {
					filepath = args.filepath,
					mode = "append",
					edits = {
						{
							oldText = args.oldText,
							newText = args.newText,
							replaceAll = args.replaceAll == true,
						},
					},
				}, opts)
			end,
		},
		schema = {
			type = "function",
			["function"] = {
				name = "edit_file",
				description = table.concat({
					"Edit a file by replacing one piece of its text. One edit per call; make several calls for several edits.",
					"oldText must match the file exactly, including whitespace and indentation, and must be unique in the file:",
					"include enough surrounding lines (a function signature, a neighbouring statement) to make it so, or set replaceAll to replace every occurrence.",
					"newText is the replacement. Read the file first so oldText is copied from it, not remembered.",
					"To delete text, pass an empty newText.",
				}, "\n"),
				parameters = {
					type = "object",
					properties = {
						filepath = {
							type = "string",
							description = "The absolute path of the file to edit",
						},
						oldText = {
							type = "string",
							description = "The exact text to find and replace",
						},
						newText = {
							type = "string",
							description = "The text to put in its place",
						},
						replaceAll = {
							type = "boolean",
							description = "Replace every occurrence of oldText instead of requiring a unique match. Defaults to false",
						},
					},
					required = { "filepath", "oldText", "newText" },
					additionalProperties = false,
				},
				strict = true,
			},
		},
		output = vim.tbl_extend("force", {}, stock.output, {
			---The stock prompt counts `args.edits`, which this tool does not have
			---@param self table
			---@return string
			prompt = function(self)
				return ("Apply the edit to `%s`?"):format(vim.fn.fnamemodify(self.args.filepath, ":."))
			end,
		}),
	})
end

return M
