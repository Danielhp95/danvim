# color-refs.nvim — design

Date: 2026-08-07

## Problem

Neovim has plugins that show a color swatch next to literal color values
(hex, `rgb()`, `hsl()`, ...) in a buffer — but none of them track *variable
references*. If a value is defined once (`local a = "#deadbeef"`) and used
later (`print(a)`), only the definition site gets a swatch; the reference
site shows nothing, even though the color is exactly as knowable there.

The motivating case is `lua/danvim/palette.lua`: color constants are defined
once and referenced by name throughout the rest of the config (see the
screenshot this spec originated from — an LSP inlay hint on `p.steel`
showing its string value, but no color swatch).

## Scope

- New standalone Neovim plugin, own git repo: `~/Projects/color-refs.nvim`.
- No dependency on an existing colorizer plugin (see "Approach" below for
  why).
- Color formats: hex (`#rgb`, `#rrggbb`, `#rrggbbaa`), `rgb()`, `rgba()`,
  `hsl()`. No named CSS colors, no Tailwind classes, no ANSI/xterm codes.
- Reference tracking: same-buffer, scope-local only, via treesitter's
  `locals` queries. No cross-file / LSP-references resolution.
- Rendering: a colored swatch as virtual text placed before the value —
  both at the literal definition and at every reference to it. No
  background-highlight or foreground-recolor rendering modes.
- Filetype-agnostic: works on any filetype with a treesitter parser and a
  `locals` query available; no per-language special-casing beyond that.

Out of scope (not requested): color picker/editing UI, cross-file
reference resolution, named/Tailwind/ANSI color formats, background or
foreground rendering modes, a formal automated test suite.

## Approach

Considered depending on `nvim-highlight-colors` (or a fork of it) for
literal-color detection and layering reference-tracking on top. Rejected:
its public API (`turnOn/turnOff/toggle/format`) doesn't expose a "find
colors in this buffer" function, so a companion module would still need
its own hex/rgb/hsl-to-color parser to resolve what a variable's
assignment evaluates to before it could render anything at a reference
site. Since that parser is required either way, and the reference-tracking
half of the feature is the actual bulk of the work, depending on an
external plugin buys little beyond one more moving part and a second
rendering style to keep visually consistent with the first. A small,
fully-owned module was chosen instead, consistent with how the rest of
`danvim` is built (`lua/danvim/palette.lua`, `lua/danvim/yazi_fuzzy_open.lua`
are both hand-written, not vendored).

## Architecture

```
color-refs.nvim/
  plugin/color-refs.lua       -- entrypoint: defines :ColorRefs user command
  lua/color-refs/
    init.lua                  -- setup(), public API, autocmd wiring
    parse.lua                 -- string -> resolved hex color
    locals.lua                -- treesitter locals: definition -> references
    render.lua                -- extmark virtual-text swatches
  README.md
  LICENSE
```

### `parse.lua`

`color_at(text) -> hex_string | nil` — pure function. The only place
format-specific parsing logic lives:
- `#rgb`, `#rrggbb`, `#rrggbbaa`
- `rgb(r, g, b)` / `rgb(r g b)`
- `rgba(r, g, b, a)`
- `hsl(...)`, including an optional `/ a` alpha component

### `locals.lua`

- `definitions_with_colors(bufnr) -> {name, def_node, hex}[]` — queries the
  buffer's `locals` captures for `@local.definition`; for each, checks
  whether its RHS text parses as a color via `parse.color_at`.
- `references_for(def_node) -> node[]` — for a given definition, returns
  the `@local.reference` nodes treesitter's locals query resolves to the
  same definition. Scoping is handled by the locals query itself — no
  manual scope-walking needed.

### `render.lua`

- `apply(bufnr, sites)` where `sites = {row, col, hex}[]` — clears the
  plugin's extmark namespace for the buffer, then places one virtual-text
  swatch before each site. Highlight groups are per-hex-value and cached
  (`ColorRefs_<hex>`) so repeated colors reuse one highlight group.

### `init.lua`

- `setup(opts)`: `{ filetypes = nil, swatch = "██", debounce_ms = 150 }`.
  `filetypes = nil` means "all filetypes with a treesitter parser."
- On buffer attach (`FileType` autocmd, filtered by `filetypes` and by
  treesitter parser availability): run an initial full pass.
- On `TextChanged` / `TextChangedI`: debounce (`vim.uv.new_timer`, default
  150ms) then re-run both passes and re-render.
- Each pass:
  1. Literal pass — walk buffer nodes, collect `{row, col, hex}` for every
     node whose text parses as a color via `parse.color_at`.
  2. Reference pass — for each `definitions_with_colors` entry, collect
     `{row, col, hex}` for the definition node itself and every node from
     `references_for`.
  3. Merge both lists, call `render.apply`.
- If `vim.treesitter.get_parser(bufnr)` fails (`pcall`-wrapped) — no
  parser for this filetype — skip the reference pass entirely and fall
  back to literal-only (regex-based, not treesitter-based) detection, so
  the plugin still does *something* useful on unparsed filetypes.

## Integration into danvim

- New `lua/danvim/plugins/color_refs.lua`, added to the return list
  assembled by `lua/danvim/plugins/init.lua` (or wherever plugin modules
  are aggregated — matches the existing pattern in `style.lua`).
- Lazy.nvim spec:
  - During development: `{ dir = "~/Projects/color-refs.nvim", dev = true,
    config = function() require("color-refs").setup({}) end }`.
  - Once pushed to GitHub: swap to the GitHub URL spec, and add it to
    `flake.nix`'s plugin list the same way other GitHub-sourced plugins
    are declared there.

## Testing

No automated test suite (not requested, and treesitter/extmark behavior
is easiest to validate visually). Manual validation:
- `lua/danvim/palette.lua` itself: literal hex definitions get swatches,
  and every `p.<name>` reference elsewhere in the config gets a matching
  swatch (the exact case from the originating screenshot).
- A CSS file using `rgb()`/`hsl()` literals, to confirm the literal pass
  works outside Lua. CSS custom properties (`--x: #fff` / `var(--x)`) are
  not lexical locals the way a JS/Lua/Python variable is, so nvim-treesitter's
  `locals` query for CSS may not capture them as a definition/reference
  pair — if so, `var()` usages simply won't get a reference swatch, which
  is an acceptable gap rather than a bug to chase.
- Deleting a definition line and confirming its reference swatches clear
  on the next debounced pass.
