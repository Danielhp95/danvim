-- danvim.codecompanion_skills -- Claude-style "skills" for CodeCompanion.
--
-- A "skill" is just a directory containing a SKILL.md whose YAML frontmatter
-- carries a `name` and a `description`, plus whatever reference files, assets
-- and scripts the instructions want to reach for. Claude Code discovers those
-- under ~/.claude/skills (personal) and <cwd>/.claude/skills (project); this
-- module reads the exact same directories, so one set of skills serves both
-- Claude Code and the local ollama model with nothing duplicated or synced.
--
-- The mechanism being reproduced is progressive disclosure, and it is the whole
-- point -- without it you may as well paste the file in by hand:
--
--   level 1  every skill's name + description is injected once, as a tool
--            system prompt. ~700 tokens for the eight skills here, so it can
--            sit in every chat without crowding a 64k window.
--   level 2  the model calls skill{name=...} and gets that SKILL.md's body,
--            plus the text of every bundled file the body actually names.
--   level 3  anything left over -- scripts, generated output, files nothing
--            points at -- is listed by path, and the model calls
--            skill{name=..., file="references/dart-cli.md"} to pull one in.
--
-- Level 3 is why this is a tool rather than a `read_file` call: skills live
-- outside the project root, which the file tools are scoped to.
--
-- Claude Code leaves ALL of the bundled files at level 3, because a frontier
-- model reliably makes the follow-up call. qwen3-coder:30b does not: it reads
-- "use the format in ADR-FORMAT.md", never fetches it, and invents a format.
-- So the cited files are promoted to level 2 here (see `cited_by`). That is a
-- deliberate divergence, and the only one -- the framing around the body is
-- otherwise aimed at matching what Claude Code does with a loaded skill.
--
-- API NOTE: written against codecompanion 19.x. Tools are resolved by
-- tool_registry.lua the moment they are *added* to a chat, not when they are
-- called, so the `callback` below runs at chat-open time and the catalogue it
-- builds is always current -- add a skill, open a new chat, it is there.

local M = {}

local uv = vim.uv or vim.loop

---@class danvim.SkillsOpts
---@field roots? string[] Directories to scan; later entries win on name clashes
---@field max_bytes? integer Truncate any single payload larger than this
---@field inline_budget? integer Total bytes of cited reference files pulled in
M.opts = {
  roots = nil,
  max_bytes = 48 * 1024,
  -- Ceiling on the reference files inlined alongside a SKILL.md (see
  -- `cited_by` below). 24k of text is ~6k tokens against a 64k window, which
  -- is affordable; the alternative -- a tool call the model has to remember to
  -- make -- is what was going wrong.
  inline_budget = 24 * 1024,
}

-- Files worth pasting into the prompt. A skill's other bundled files are
-- scripts and assets: things its instructions tell you to *run*, not to read,
-- so they are listed by path for run_command rather than inlined.
local INLINEABLE = {
  md = true,
  markdown = true,
  txt = true,
  text = true,
  rst = true,
  json = true,
  yaml = true,
  yml = true,
  toml = true,
  csv = true,
}

---Personal first, project second, so a repo-local skill shadows a personal one
---of the same name -- matching Claude Code's precedence.
---@return string[]
local function default_roots()
  return {
    vim.fs.normalize("~/.claude/skills"),
    vim.fs.joinpath(vim.fn.getcwd(), ".claude", "skills"),
  }
end

---Read the YAML frontmatter of a SKILL.md.
---
---Deliberately a 30-line reader and not a YAML implementation: skills only ever
---use flat string scalars, so the cost of a real parser buys nothing. Handles
---quoted values and folded/literal blocks, which do show up in the wild.
---@param lines string[]
---@return table|nil frontmatter, integer|nil body_start_line
local function parse_frontmatter(lines)
  if lines[1] ~= "---" then
    return nil
  end

  local fm, key, i = {}, nil, 2
  while i <= #lines and lines[i] ~= "---" do
    local line = lines[i]
    local k, v = line:match("^([%w_%-]+):%s*(.*)$")
    if k then
      key = k
      -- `>`, `>-`, `|`, `|-` introduce a block scalar: the value is on the
      -- indented lines that follow, so start empty and let them accumulate.
      fm[k] = v:match("^[|>][-+]?$") and "" or v
    elseif key and line:match("^%s+%S") then
      local cont = line:gsub("^%s+", "")
      fm[key] = fm[key] == "" and cont or (fm[key] .. " " .. cont)
    end
    i = i + 1
  end

  -- An unterminated block is a malformed file, not a skill with no body.
  if lines[i] ~= "---" then
    return nil
  end

  for k, v in pairs(fm) do
    fm[k] = (v:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1"))
  end
  return fm, i + 1
end

---Scan one root for skill directories, writing into `out` keyed by skill name.
---@param root string
---@param out table<string, table>
local function scan_root(root, out)
  local fs = uv.fs_scandir(root)
  if not fs then
    return
  end

  while true do
    local entry, kind = uv.fs_scandir_next(fs)
    if not entry then
      break
    end
    if kind == "directory" or kind == "link" then
      local dir = vim.fs.joinpath(root, entry)
      local path = vim.fs.joinpath(dir, "SKILL.md")
      if uv.fs_stat(path) then
        -- Only the head of the file: the body is re-read at call time so that
        -- editing a SKILL.md takes effect without restarting Neovim.
        local ok, head = pcall(vim.fn.readfile, path, "", 60)
        if ok then
          local fm = parse_frontmatter(head)
          if fm and fm.description then
            local name = fm.name or entry
            out[name] = {
              name = name,
              description = fm.description,
              path = path,
              dir = dir,
              -- Skills can opt out of being picked by the model, staying
              -- available as an explicit /skill invocation.
              model_invocable = fm["disable-model-invocation"] ~= "true",
            }
          end
        end
      end
    end
  end
end

---All discovered skills, sorted by name.
---@return table[]
function M.discover()
  local found = {}
  for _, root in ipairs(M.opts.roots or default_roots()) do
    scan_root(root, found)
  end

  local list = vim.tbl_values(found)
  table.sort(list, function(a, b)
    return a.name < b.name
  end)
  return list
end

---@param name string
---@return table|nil
local function find(name)
  for _, s in ipairs(M.discover()) do
    if s.name == name then
      return s
    end
  end
end

---Everything in the skill directory except SKILL.md itself -- the payloads the
---body is allowed to cite.
---@param dir string
---@return string[]
local function bundled_files(dir)
  local out = {}
  for rel, kind in vim.fs.dir(dir, { depth = 4 }) do
    if kind == "file" and rel ~= "SKILL.md" then
      table.insert(out, rel)
    end
  end
  table.sort(out)
  return out
end

---Does the SKILL.md body actually point at this file?
---
---Plain substring match on the relative path, which covers every citation style
---the skills here use: bare (`state.json`), markdown link
---([CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md)) and prefixed
---(`skills/brainstorming/visual-companion.md`). A false positive costs a few
---hundred wasted tokens; a false negative costs the model the procedure.
---@param body string
---@param rel string
---@return boolean
local function cited_by(body, rel)
  return body:find(rel, 1, true) ~= nil
end

---@param rel string
---@return boolean
local function is_inlineable(rel)
  local ext = rel:match("%.([%w_]+)$")
  return ext ~= nil and INLINEABLE[ext:lower()] == true
end

---Render the leftover files compactly.
---
---Collapse any directory holding more than three of them: neovim-news-update
---writes one report per run and had grown to sixteen, so a flat list buried the
---skill's own instructions under a wall of filenames it never referred to.
---@param rels string[]
---@return string[]
local function summarise_files(rels)
  local counts, order = {}, {}
  for _, rel in ipairs(rels) do
    local dir = rel:match("^(.*)/[^/]+$") or ""
    if not counts[dir] then
      counts[dir] = {}
      table.insert(order, dir)
    end
    table.insert(counts[dir], rel)
  end

  local out = {}
  for _, dir in ipairs(order) do
    local group = counts[dir]
    if dir ~= "" and #group > 3 then
      table.insert(out, ("%s/ (%d files)"):format(dir, #group))
    else
      vim.list_extend(out, group)
    end
  end
  return out
end

---@param path string
---@return string|nil content, string|nil err
local function read_capped(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, ("Could not read `%s`"):format(path)
  end
  local content = table.concat(lines, "\n")
  if #content > M.opts.max_bytes then
    content = content:sub(1, M.opts.max_bytes)
      .. ("\n\n[truncated at %d bytes]"):format(M.opts.max_bytes)
  end
  return content
end

---Load a skill body, or one of its bundled files.
---@param name string
---@param file string? Relative path within the skill directory
---@return { status: "success"|"error", data: string }
function M.load(name, file)
  local skill = find(name)
  if not skill then
    local available = vim.tbl_map(function(s)
      return s.name
    end, M.discover())
    return {
      status = "error",
      data = ("No skill named `%s`. Available: %s"):format(name, table.concat(available, ", ")),
    }
  end

  if file and file ~= "" then
    -- Confine reads to the skill directory: `file` comes from the model.
    local target = vim.fs.normalize(vim.fs.joinpath(skill.dir, file))
    if not vim.startswith(target, vim.fs.normalize(skill.dir) .. "/") then
      return { status = "error", data = ("`%s` is outside the `%s` skill"):format(file, name) }
    end
    local content, err = read_capped(target)
    if not content then
      return { status = "error", data = err }
    end
    return {
      status = "success",
      data = ("# `%s`, from the `%s` skill\n\n%s"):format(file, name, content),
    }
  end

  local body, err = read_capped(skill.path)
  if not body then
    return { status = "error", data = err }
  end

  -- Strip the frontmatter: the description is re-stated in the header below,
  -- and the raw YAML only invites the model to comment on it.
  local lines = vim.split(body, "\n")
  local _, body_start = parse_frontmatter(lines)
  if body_start then
    body = table.concat(vim.list_slice(lines, body_start), "\n")
  end
  body = vim.trim(body)

  -- Split the bundle: files the instructions actually name get pasted in,
  -- everything else gets listed. Claude Code can afford to leave all of it
  -- behind a tool call because it reliably makes the call; a 30B local model
  -- does not, and then works from half a procedure -- which is the failure
  -- this partition exists to fix.
  local refs, rest = {}, {}
  local budget = M.opts.inline_budget
  for _, rel in ipairs(bundled_files(skill.dir)) do
    local content
    if is_inlineable(rel) and cited_by(body, rel) then
      content = read_capped(vim.fs.joinpath(skill.dir, rel))
    end
    if content and #content <= budget then
      budget = budget - #content
      table.insert(refs, { rel = rel, content = content })
    else
      table.insert(rest, rel)
    end
  end

  -- MARKDOWN, NOT XML, and this is not a style preference. An earlier cut of
  -- this wrapped the body in <skill>/<instructions>/<reference> tags, the way
  -- Claude Code does. qwen3-coder:30b answers a tagged prompt by *imitating*
  -- it: asked to act on a skill it would open with `<skill name=...>` and read
  -- the whole thing back, or invent `<action><create_file path=...>` instead
  -- of calling the tool it had been given. Tag soup looks like the tool-call
  -- grammar it was trained to emit, so it emits some. The identical content in
  -- markdown gets followed instead of echoed -- measured on the same prompt,
  -- twice each, before this was written.
  local parts = {
    ("# Skill: %s"):format(name),
    "",
    skill.description,
    "",
    -- Every clause below answers a way the model was mishandling a loaded
    -- skill: narrating it back, asking permission to use it, quietly
    -- preferring its own approach, or taking the skill's own directory for the
    -- project it was supposed to be working on.
    "The user wrote the procedure below for exactly this task. Follow it now, step by",
    "step, in order. Do not summarise it back to them, do not repeat it, do not ask",
    "whether to use it, and do not substitute an approach of your own.",
    "",
    ("The skill's own files live in `%s`."):format(skill.dir),
    "That is what it means by `<skill-dir>`. It is not the project: read and write the",
    "project itself in the current working directory, as usual.",
    "",
    "---",
    "",
    body,
  }

  if #refs > 0 then
    table.insert(parts, "")
    table.insert(parts, "---")
    table.insert(parts, "")
    table.insert(parts, "# Files this skill refers to")
    for _, ref in ipairs(refs) do
      table.insert(parts, "")
      table.insert(parts, ("## `%s`"):format(ref.rel))
      table.insert(parts, "")
      table.insert(parts, ref.content)
    end
  end

  if #rest > 0 then
    table.insert(parts, "")
    table.insert(parts, "---")
    table.insert(parts, "")
    table.insert(parts, "# Other files in the skill directory")
    table.insert(parts, "")
    for _, rel in ipairs(summarise_files(rest)) do
      table.insert(parts, ("- %s"):format(rel))
    end
    table.insert(parts, "")
    table.insert(
      parts,
      ('Read one with skill{name="%s", file="<path>"}; run one by its full path under the'):format(name)
    )
    table.insert(parts, "skill directory above.")
  end

  -- Last line in the payload on purpose: whatever else the model skims, it
  -- reads the end of the block, and this is where it is told to act.
  table.insert(parts, "")
  table.insert(parts, "---")
  table.insert(parts, "")
  table.insert(parts, ("Now carry out the `%s` skill, starting at its first step."):format(name))

  return { status = "success", data = table.concat(parts, "\n") }
end

--- The tool ---------------------------------------------------------------

---@return table
function M.tool()
  local names, catalogue = {}, {}
  for _, s in ipairs(M.discover()) do
    if s.model_invocable then
      table.insert(names, s.name)
      table.insert(catalogue, ("- `%s`: %s"):format(s.name, s.description))
    end
  end

  local params = {
    name = {
      type = "string",
      description = "The name of the skill to load.",
    },
    file = {
      type = "string",
      description = "Optional. A file bundled with the skill, relative to its directory, as listed under 'Other files in the skill directory'. Omit to load the skill's main instructions -- the files those instructions cite come back with them already.",
    },
  }
  -- Constraining to an enum matters more for a 30B local model than it would
  -- for a frontier one: it removes any opportunity to invent a skill name.
  if #names > 0 then
    params.name.enum = names
  end

  return {
    name = "skill",
    cmds = {
      function(_, args, _)
        return M.load(args.name, args.file)
      end,
    },
    schema = {
      type = "function",
      ["function"] = {
        name = "skill",
        description = "Load the instructions for a named skill. Skills are procedures the user has written for specific tasks; the catalogue is in your system prompt. Call this BEFORE starting work that a skill covers.",
        parameters = {
          type = "object",
          properties = params,
          required = { "name" },
        },
      },
    },
    ---Level 1: the catalogue. Injected once per chat rather than per call.
    system_prompt = function()
      if #catalogue == 0 then
        return "No skills are currently available."
      end
      return ([[# Skills

The user has written the following skills -- procedures for specific tasks. Each entry is `name`: when to use it.

%s

If the user's request matches a skill's description, call the `skill` tool with that name and follow the instructions it returns before doing anything else. Do not guess at a procedure a skill already documents. If nothing matches, just answer normally.]]):format(
        table.concat(catalogue, "\n")
      )
    end,
    opts = {
      -- Reading instruction files the user wrote themselves; an approval
      -- prompt here would be friction with nothing behind it.
      require_approval_before = false,
    },
    output = {
      success = function(self, stdout, meta)
        meta.tools.chat:add_tool_output(self, vim.iter(stdout):flatten():join("\n"), "Loaded skill")
      end,
      error = function(self, stderr, meta)
        meta.tools.chat:add_tool_output(self, vim.iter(stderr):flatten():join("\n"))
      end,
    },
  }
end

--- The slash commands -----------------------------------------------------

-- Slash command names codecompanion 19.22 already uses. A skill whose name
-- collides with one of these would shadow it silently -- SlashCommands:execute
-- checks for a `callback` before it looks at the built-in `path`, and
-- tbl_deep_extend leaves both on the merged entry -- so those get a prefix.
local RESERVED = {}
for _, name in ipairs({
  "acp_session_options",
  "buffer",
  "command",
  "compact",
  "fetch",
  "file",
  "fork",
  "help",
  "image",
  "mcp",
  "now",
  -- Not a command: slash_commands.opts is the settings sub-table for this
  -- section, and a skill named `opts` would overwrite it rather than sit
  -- beside it.
  "opts",
  "resume",
  "rules",
  "share",
  "skill",
  "symbols",
}) do
  RESERVED[name] = true
end

---Put a skill into a chat as a system message.
---@param chat table
---@param name string
---@return nil
function M.inject(chat, name)
  local result = M.load(name)
  if result.status ~= "success" then
    return vim.notify(result.data, vim.log.levels.ERROR)
  end

  local id = "<skill>" .. name .. "</skill>"

  -- add_message appends unconditionally, so without this a second invocation
  -- of the same skill puts another copy of the whole payload in the window.
  -- (chat.context:add already dedupes on the id, so only the message leaks.)
  for _, msg in ipairs(chat.messages) do
    if msg.context and msg.context.id == id then
      return vim.notify(("The `%s` skill is already loaded"):format(name))
    end
  end

  chat:add_message({
    -- SYSTEM, not USER, and this is the difference that matters most.
    -- Injected as a user message the payload reads as something the user
    -- pasted -- so the model replies *about* it, summarising the procedure
    -- back instead of running it, and the real request that follows becomes
    -- the second of two user turns. As a system message it lands in the same
    -- block as the tool prompt and the skill catalogue, where instructions
    -- live, and the user's request stays the only thing they said.
    role = require("codecompanion.config").constants.SYSTEM_ROLE,
    content = result.data,
  }, { context = { id = id }, visible = false })

  -- Load-bearing, not decoration: Chat:check_context() reconciles the message
  -- list against the `> Context:` block in the chat buffer on every submit,
  -- and drops any message whose context id is not listed there. Skip this call
  -- and the skill is deleted from the payload before it is sent.
  chat.context:add({ source = "slash_command", name = "skill", id = id })
  vim.notify(("Loaded the `%s` skill"):format(name))
end

---One slash command per skill, the way Claude Code exposes them: `/grilling`
---loads the grilling skill outright, with its description in the completion
---menu, and no picker in the way.
---
---Called while the plugin spec is being built, so the catalogue is fixed at
---startup: a skill added afterwards has no command of its own until Neovim
---restarts. Only the *list* is frozen -- M.load re-reads from disk on every
---invocation, so editing a SKILL.md still takes effect immediately, and /skill
---below still finds skills that have no command yet.
---@return table<string, table>
function M.slash_commands()
  local out = {}
  for _, skill in ipairs(M.discover()) do
    local key = RESERVED[skill.name] and ("skill-" .. skill.name) or skill.name
    out[key] = {
      callback = function(chat)
        M.inject(chat, skill.name)
      end,
      description = skill.description,
      opts = { contains_code = false },
    }
  end
  return out
end

---`/skill` -- pick a skill from a list and inject it.
---
---Kept alongside the per-skill commands as the discovery path: it lists what is
---on disk right now, including anything added since startup, and shows the
---descriptions side by side when you know the job but not which skill covers
---it. Like the per-skill commands, and unlike the tool, it offers skills marked
---disable-model-invocation.
---@param chat table
function M.slash_command(chat)
  local skills = M.discover()
  if #skills == 0 then
    return vim.notify("No skills found in ~/.claude/skills or ./.claude/skills", vim.log.levels.WARN)
  end

  vim.ui.select(skills, {
    prompt = "Skill",
    format_item = function(s)
      return ("%-24s %s"):format(s.name, s.description:sub(1, 90))
    end,
  }, function(choice)
    if not choice then
      return
    end
    M.inject(chat, choice.name)
  end)
end

return M
