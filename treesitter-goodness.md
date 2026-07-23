# Treesitter goodness you're not using

A review of what your config already covers and what's still on the table.
Config reviewed: `lua/danvim/plugins/treesitter.lua`, `options.lua`, `keybindings.lua`
(nvim 0.13.0-nightly, nvim-treesitter `main` branch).

**Already using** (skip these in other guides): highlighting via `vim.treesitter.start()`,
treesitter foldexpr, textobjects select/swap/move with repeatable `;`/`,`,
treesitter-context, and the new core node selection (`vim.treesitter._select`
on `<CR>`/`<BS>`), which replaced the old incremental-selection module.

---

## 1. Treesitter indentation (`indentexpr`)

You rely on `autoindent`/`copyindent`, which just copies the previous line.
The `main` branch ships an experimental indent module that computes indent from
the syntax tree — noticeably better for Lua, Python continuation lines, and
multi-line function calls. Add to your `FileType` autocmd next to `foldexpr`:

```lua
vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
```

It's per-language quality, so if a language misbehaves, gate it on a list.

## 2. Auto-install missing parsers

Your `config` does `local treesitter = require("nvim-treesitter")` and then
never uses it — `vim.treesitter.language.add(lang)` only succeeds if the parser
already exists, so new filetypes silently get no highlighting. The `main`
branch API makes on-demand install easy:

```lua
callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match) or args.match
    if vim.treesitter.language.add(lang) then
        start(args.buf, lang)
    elseif vim.tbl_contains(require("nvim-treesitter.config").get_available(), lang) then
        require("nvim-treesitter").install(lang):await(function()
            start(args.buf, lang)
        end)
    end
end
```

(Since you build parsers through nix, you may prefer *not* to do this — but
then at least drop the dead `local treesitter` line.)

## 3. Treesitter fold text

Since 0.10, an **empty** `foldtext` gives you the first line of the fold with
full treesitter highlighting instead of the grey `+--- 12 lines:` string:

```lua
vim.o.foldtext = ""
vim.opt.fillchars:append({ fold = " " })
```

Also worth fixing while you're in `options.lua`: it sets
`foldmethod = "indent"` globally while `foldexpr` is the treesitter one — the
expr is dead weight until the autocmd in `treesitter.lua` flips the window to
`expr`. Setting `foldmethod = "expr"` globally (with `foldlevel = 99` so files
open unfolded) would let you delete the per-window lines in the autocmd.

## 4. Textobjects you haven't mapped

The queries ship with more captures than the ones you bound. High-value ones:

| Mapping idea | Capture | What it grabs |
|---|---|---|
| `a=` / `i=` | `@assignment.outer` / `.inner` | whole assignment / just RHS |
| `l=` / `r=` | `@assignment.lhs` / `.rhs` | either side — great with `cir` |
| `aa` / `ia` | `@parameter.outer` / `.inner` | you swap parameters but can't select one! |
| `af` / `if` | `@call.outer` / `.inner` | a function *call* (you only have defs) |
| `a/` | `@comment.outer` | delete a whole comment with `da/` |
| `aR` / `iR` | `@return.outer` / `.inner` | `ciR` to rewrite a return value |
| `ao` / `io` | `@loop.outer` / `.inner` | you jump to loops with `]o` but can't select them |
| `ai` / `ii` | `@conditional.outer` / `.inner` | same story: `]d` jumps, nothing selects |

Note the asymmetry in your current setup: several categories have *move*
mappings but no *select* mapping (loops, conditionals) or vice versa.

## 5. `@spell` — spellcheck only where it makes sense

Treesitter queries mark comments/strings with `@spell` and code with
`@nospell`. With highlighting active, `vim.o.spell = true` (or per-filetype)
only flags typos in comments and prose — none of the classic "every identifier
is misspelled" noise. You currently don't enable spell anywhere.

## 6. Custom queries via `after/queries/`

Drop-in extension point, no plugin needed. Two classics:

**Extra injections** — highlight SQL/bash inside strings, e.g.
`after/queries/lua/injections.scm`:

```scheme
;; extends
((string content: (string_content) @injection.content)
  (#match? @injection.content "^%s*[Ss][Ee][Ll][Ee][Cc][Tt]")
  (#set! injection.language "sql"))
```

**Custom textobjects** — add your own captures to
`after/queries/<lang>/textobjects.scm` and bind them exactly like the built-in
ones. Your `]z` → `@fold` mapping already shows you know the multi-query-group
trick; this is the authoring side of it.

## 7. Dev/inspection tools (built into core)

- `:Inspect` — what captures/highlights are under the cursor (debug "why is
  this the wrong color").
- `:InspectTree` — live syntax tree in a split; press `a` to toggle anonymous
  nodes, `i` for the `:EditQuery` playground.
- `:EditQuery` — interactive query editor with live match highlighting; the
  fastest way to write the `.scm` files from §6.

## 8. Plugins in your own commented-out graveyard

Your `Treesitter` spec has these commented out — a reminder list, ranked:

- **`rainbow-delimiters.nvim`** — per-nesting-level bracket colors. Cheap,
  works everywhere, especially nice in Lua-heavy config editing.
- **`nvim-treesitter-textsubjects`** — "smart" single textobject (`.`) that
  expands by context instead of you naming the node. Partially redundant now
  with core's `<CR>` expand-selection, so maybe skip.
- **`nvim-treesitter-refactor`** — master-branch only, mostly superseded by
  LSP rename/highlight. Safe to delete the comment.

Not in your graveyard but worth knowing:

- **`vim-matchup`** — makes `%` jump between `if/end`, `function/end` etc.
  using treesitter, and can show the match in a popup. The single biggest
  day-to-day upgrade on this list for Lua editing.
- **`treewalker.nvim`** — up/down/left/right movement over AST nodes
  (siblings/parents); complements your `<C-CR>`/`<C-BS>` sibling selection
  with actual cursor movement.
- **`otter.nvim`** — LSP features *inside* injected code blocks (lua in
  markdown, SQL in strings). Pairs well with §6 injections and your
  markview/markdown workflow.

## 9. Small wins

- **Sticky context jump**: treesitter-context ships
  `require("treesitter-context").go_to_context(vim.v.count1)` — bind e.g.
  `[c` to jump to the function/class shown in the context window.
- **`O`/`o` in visual mode inside `:InspectTree`** — not a config change, just
  underused.
- **Comment `commentstring`**: core `gc` commenting is treesitter-aware since
  0.10 (correct comment leader in embedded languages) — you get this for free
  already, mentioned so you don't install `ts-context-commentstring`.
