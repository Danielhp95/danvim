# danvim configuration review (2026-06)

Neovim 0.12 shipped in March 2026 with `vim.pack`, native auto-completion (`vim.lsp.completion`), and a long list of native LSP/UI improvements. This review focuses on what those changes (plus folke's `snacks.nvim` becoming the de-facto QoL bundle) mean for your config.

## Top-impact changes

- **Consolidate UI plugins into `snacks.nvim`.** You already pull in `snacks.nvim`, but you still install `toggleterm.nvim`, `vim-floaterm`, `dressing.nvim`, and a custom `vim._core.ui2` integration. `snacks.terminal`, `snacks.input`, `snacks.notifier`, and `snacks.statuscolumn` can replace those with one well-integrated source.
- **Drop the experimental `vim._core.ui2` block.** Nvim 0.12 ships a native floating cmdline/messages stack. The `vim._core.ui2` API you call in `options.lua` is an internal/experimental module and is fragile across nightlies.
- **Migrate LSP off `nvim-lspconfig`'s setup pattern.** You already use `vim.lsp.config()` / `vim.lsp.enable()` (good) — but the plugin itself can be removed; `nvim-lspconfig` is now just a passive collection of native-LSP configs, and your `lsp.lua` defines them all inline anyway.
- **Pick one file manager.** `yazi.nvim` + `fyler.nvim` (+ snacks.explorer enabled in `snacks.lua:11`) is three overlapping tools. Yazi for fuzzy/external browsing + snacks.explorer (or fyler) for in-buffer editing is the common 2026 combo.
- **Decide between telescope and snacks.picker.** Almost every keymap under `<leader>t` already uses `snacks.picker`. Telescope is only kept for a handful of extensions (`undo`, `manix`, `dap`, `live_grep_args`). Snacks has equivalents for undo/grep-with-args/dap pickers — finishing the migration would let you delete telescope and 5+ extensions.

---

## Plugin files

### `blink.lua`
Current: full-featured blink.cmp config with copilot, avante, git, ripgrep, fuzzy-path, emoji, words sources.

- Configuration is idiomatic for blink v1.x. Keep it.
- `completion.ghost_text.enabled = false` plus the manual Copilot dismiss autocmd in `init` (`blink.lua:23-42`) is necessary only because you use `copilot.lua` suggestion ghost text — but in `copilot.lua` you already set `suggestion = { enabled = false }`. The autocmd is then a no-op; you can delete `init` entirely.
- `fuzzy.sorts = { "exact", "score", "sort_text" }` is now the default in blink v1.x — can be removed.
- Consider dropping `blink-cmp-words` (dictionary source) — it's listed as a provider but not in `default` sources (line 157), so it's dead config.
- Source ordering in `default` (`blink.lua:157`) puts `avante` first which can flood the menu in normal code; most users put `lsp` first and let copilot/avante boost via `score_offset`.

### `lsp.lua`
Current: `nvim-lspconfig` + `lazydev` + manual `vim.lsp.config(...)` blocks.

- You're already on the native pattern. `nvim-lspconfig` as a plugin can be dropped — you define all servers inline (and it's not in your nix `startupPlugins`, but referenced in the lazy spec, which means it silently does nothing). Confirm with `:Lazy`.
- Consider moving formatter selection from `conform.nvim` to using LSP `textDocument/formatting` for servers that have it (ruff_lsp, nixd) — conform is still useful for stylua/yamlfmt/jq though, so probably keep.

### `snacks.lua`
Current: most modules enabled including notifier, input, indent.

- Enable `snacks.terminal` (already on) and drop `toggleterm.nvim`, `vim-floaterm`, `term-edit.nvim` in `terminal.lua`. Snacks terminal has float/horizontal/vertical and send-line.

### `essentials.lua`
Current: which-key, autopairs, surround, codediff, flash.

- Idiomatic. One small note: `nvim-autopairs` can be replaced by `mini.pairs` if you adopt the mini suite, but autopairs is fine.

### `treesitter.lua`
Current: `main` branch of nvim-treesitter (the new rewrite), context, textobjects, FileType autocmd to start parsers.

- You're on the new `main` branch — this is the right choice for 2026. Good.
- The `FileType` autocmd at `treesitter.lua:154` is no longer required on `main` — `vim.treesitter.start()` is called automatically when a parser is installed via `:TSInstall`. Since you install parsers via nix, the autocmd is what wires them; keep it, but consider replacing with `treesitter.install()` + the official autocmd snippet from the README.
- `;` and `,` overrides (`treesitter.lua:129`) are aggressive — they replace builtin repeat-last-f/t even when not coming from a treesitter move. The `builtin_f_expr` line below restores this, so it works, but worth a comment.

### `telescope.lua`
Current: full telescope setup with 7 extensions.

- Given your keybindings already mostly use `snacks.picker`, evaluate whether telescope earns its keep. `live_grep_args` → `snacks.picker.grep({ args = ... })`. `undo` → `snacks.picker.undo` (exists). `dap` → `snacks.picker.dap_*`. `manix` is the only one without a clean snacks port.
- If you keep telescope, remove dead deps: `telescope-cheat.nvim`, `telescope-env.nvim` are seldom used.

### `file_manager.lua`
Current: yazi + fyler + (snacks.explorer enabled elsewhere).

- Pick two max. Recommended: `yazi.nvim` (external power user) + snacks.explorer (in-buffer). Drop `fyler.nvim`, or swap snacks.explorer for fyler — but three overlapping file UIs is too many.

### `git.lua`
Current: fugitive, gitsigns, diffview, vim-flog, gitlinker, diffs.nvim, lensline.

- Solid stack. `diffs.nvim` (treesitter diff highlighting) is a nice add.
- `lensline.nvim` is fine but you also have treesitter-context and inline LSP refs in 0.12 — check whether the `references` provider duplicates anything you already see.
- **Migrate `gitlinker.nvim` → `snacks.gitbrowse`:** delete the `ruifm/gitlinker.nvim` spec entry from `git.lua` and remove `gitlinker-nvim` from `flake.nix` startupPlugins. Snacks already exposes `Snacks.gitbrowse.open()`. Rebind whatever `<leader>g…` mappings you had (e.g. `gy` / `gB`) to:
  ```lua
  vim.keymap.set({ "n", "v" }, "<leader>gy", function() Snacks.gitbrowse.open({ open = function(url) vim.fn.setreg("+", url) end, notify = true }) end, { desc = "Copy git URL" })
  vim.keymap.set({ "n", "v" }, "<leader>gB", function() Snacks.gitbrowse.open() end, { desc = "Open in browser" })
  ```
  Visual mode is handled automatically (line range from the current selection).
- `vim-fugitive` is listed twice (top-level and as a dep of vim-flog). Lazy.nvim dedupes this, but worth noting.

### `style.lua`
Current: colorizer, lualine, bufferline, simple-zoom, markview, tiny-devicons-auto-colors.

- `bufferline.nvim` — fine, but if you don't actually use tab-style buffer bars, native `:tab` + `tabline` is enough. Your `H`/`L` keymaps already use `tabp`/`tabn`, not buffer cycling.
- `simple-zoom.nvim` — `snacks.zen` or `:tab split` does the same; consider dropping. Your statusline reference to `vim.t["simple-zoom"]` couples lualine to it though.

### `colorschemes.lua`
Current: ember + teide + themeInitNvim.

- These are not in `flake.nix` (only `onedarkpro-nvim` and `catppuccin-nvim` are listed). The lazy spec will silently fail for `ember-theme/nvim` etc. when running through nix-cats. Either add them to `flake.nix:259-262` or remove from lua.
- `vim.cmd.colorscheme("ember")` in the config function runs once; if you want runtime switching, use `snacks.picker.colorschemes` or `:Telescope colorscheme`.

### `dap.lua`
Current: nvim-dap + dap-view + dap-virtual-text.

- `vim.loop.cwd()` was replaced with `vim.uv.cwd()` (deprecated alias).

### `avante.lua`
Current: avante.nvim with claude-code ACP provider (Sonnet 4.6 default, Opus 4.7 alt).

- Good setup for Max-sub Claude use. The hard-coded path `~/sai/dart_vibe.md` at `avante.lua:71` is brittle — gate behind `vim.fn.filereadable()` (you do, after the defer — fine).
- Consider also setting up `olimorris/codecompanion.nvim` for inline/buffer-driven chat — your nix flake already pulls it and its plugins (`flake.nix:184-187`) but `codecompanion.lua` was deleted (per git status). The codecompanion-history/spinner/lualine plugins are installed-but-orphaned.

### `copilot.lua`
Current: copilot.lua with suggestion/panel disabled (used as a source for blink-copilot).

- Idiomatic. Could drop `cmd = "Copilot"` since `event = "InsertEnter"` will load it anyway.

### `terminal.lua`
Current: vim-floaterm + toggleterm + term-edit.

- Replace all three with `snacks.terminal` (already enabled). Your `<leader><leader>{f,h,v}` toggleterm keybinds map cleanly to `Snacks.terminal.toggle({ win = { position = "float" } })` etc.
- `term-edit.nvim` (better prompt editing) — keep separately if you find snacks.terminal's editing wanting; otherwise drop.

### `obsidian.lua`, `octo.lua`, `presentations.lua`, `previewers.lua`, `profile.lua`
- `obsidian.lua`, `octo.lua`: returning empty tables. Delete the files (and the `import = 'danvim.plugins'` loop will be slightly faster).
- `presentations.lua`: `present.nvim` from tjdevries-clone — fine if you actually present. Otherwise drop.
- `previewers.lua`: `omni-preview.nvim` — niche; keep only if used.
- `profile.lua`: keep — useful, only runs under `NVIM_PROFILE=1`.

---

## `options.lua`

- `vim.o.clipboard = "unnamed,unnamedplus"` — fine but on Nvim 0.10+ consider lazy-setting it after UIEnter to avoid startup cost from xclip/wl-clipboard probes.
- **Missing 2026 options worth adding:**
  - `vim.o.cmdheight = 0` if you adopt the native floating cmdline.
  - `vim.diagnostic.config({ virtual_text = ..., virtual_lines = ..., severity_sort = true, jump = { float = true } })` — replaces the per-keymap `border = "rounded"` hacks in `keybindings.lua:173-175`. Plus `vim.diagnostic.config({ float = { border = "rounded" } })` once.
  - `vim.lsp.inlay_hint.enable(true)` if you want them on by default.
- `vim.o.winborder = "rounded"` — good, this is a 0.11 feature and replaces per-plugin border config.
- `require('vim._core.ui2').enable(...)` (lines 71-131) — calling an underscored internal API is fragile. Either commit to native or commit to snacks; don't post-monkey-patch `msgs.set_pos`. If you want top-right messages, prefer `snacks.notifier` with `top_down = true` and `style = "compact"`.
- `vim.opt.jumpoptions = "stack,view"` is good — `view` is the new 0.11 addition.

---

## `keybindings.lua`

- **Duplicates / collisions:**
  - `<leader>a` is both the avante group (line 63) and the treesitter-textobjects swap mapping (`treesitter.lua:69`). Conflict.
  - `<leader>s` is both "spelling" group (line 156) and "source file" (line 52, `<leader>sf`) — `sf` collides with snacks-find since snacks namespace uses `<leader>t` here. Minor.
  - `<leader>gd` is declared twice as a group (lines 76 and 98 — once for normal, once for visual). Which-key will warn.
  - `<leader>gdd` defined twice on consecutive lines (105-106).
  - `<leader><leader>s` defined twice in terminal block (lines 253, 257) — once normal (send line), once visual (send selection). That's intentional but worth a `mode` arg on both.
- **Could move to plugin specs (`keys = {...}`):** all the gitsigns mappings (lines 70-91), all the trouble mappings, dap mappings — keeps plugins lazy-loadable and consolidates ownership.
- **Superseded by defaults / native:**
  - `]q`/`[q` (lines 57-58) — Nvim 0.11+ does NOT ship these — keep yours.
  - `<leader>dn`/`<leader>dp` (next/prev diagnostic) — in 0.11+ use `vim.diagnostic.jump({ count = 1, float = true })`; `goto_next`/`goto_prev` are deprecated.
  - `vim.lsp.buf.code_action()`, `rename()`, etc. — these have default keymaps in 0.11+ (`grn`, `gra`, `grr`, `gri`). You can lean on those and drop the explicit `<leader>l*` mappings, or keep `<leader>l` for discoverability.
- `H`/`L` for tab nav (line 41-42) — overrides default `H`/`L` (top/bottom of screen). Fine if intentional.
- `Print_last_notification` (line 135) as a global — should be `local` or put on a namespaced table. Pollutes `_G`.
- `vertical_layout` variable at line 179 is unused.

---

## `aucmds.lua`

- `vim.hl.on_yank()` (line 6) — correct in 0.11+; was `vim.highlight.on_yank` previously.
- The "create missing directories on save" autocmd — good idiom, keep.
- `ColorScheme` autocmd bolding Visual — works but fragile; many colorschemes set `Visual` after `ColorScheme` fires via `link`. Consider using `vim.api.nvim_set_hl(0, "Visual", { bold = true, force = true })` or applying on a `VimEnter` after colorscheme load.

---

## `builtin_plugins.lua`

Just `packadd nvim.undotree`. Fine. If you adopt `vim.pack` later this is where to migrate.

---

## Summary checklist (in priority order)

1. Pick one of: native 0.12 UI / snacks for messages+cmdline+notifications — currently `vim._core.ui2` fights with snacks.
2. Remove dead/empty plugin files (`obsidian.lua`, `octo.lua`).
3. Consolidate file managers (yazi + snacks.explorer OR yazi + fyler; not both).
4. Consolidate terminal (snacks.terminal, drop toggleterm + floaterm + term-edit).
5. Add `vim.diagnostic.config()` block to replace per-keymap border options.
6. Clean keybinding duplicates (`<leader>gd`, `<leader>gdd`, `<leader>a`).
7. Migrate `gitlinker.nvim` → `snacks.gitbrowse`.

## Sources

- [Neovim 0.12 release / vim.pack](https://neovim.io/doc/user/pack/)
- [vim.lsp.config / native LSP guide (Nvim 0.11+)](https://neovim.io/doc/user/lsp.html)
- [blink.cmp](https://github.com/saghen/blink.cmp)
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [snacks.gitbrowse](https://github.com/folke/snacks.nvim/blob/main/docs/gitbrowse.md)
- [lazydev.nvim](https://github.com/folke/lazydev.nvim)
- [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view)
- [Native LSP autocompletion](https://blog.viktomas.com/graph/neovim-native-built-in-lsp-autocomplete/)


- Add https://github.com/gregorias/nvim-surround-wk as a dependency to wherever nvim-surround lives
- I like the new https://github.com/kremovtort/tabterm.nvim. Change the float-term setup that I have with tabterm instead, keep the same keybindings and suggest new ones 
