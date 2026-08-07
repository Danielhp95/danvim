# color-refs.nvim — design

Date: 2026-08-07
Status: **built** — see "As built" at the end for where the code departs from
this document. The design below is kept as written, not retrofitted.

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

## As built

Implemented at `~/Projects/color-refs.nvim` (commit `fae26b4`), wired into
danvim via `lua/danvim/plugins/color_refs.lua`. Four deviations from the design
above, all discovered while building it.

### 1. `require`-resolution, because the spec contradicted itself

"Scope" says reference tracking is same-buffer only. "Testing" says every
`p.<name>` in the rest of the config must get a swatch. Both cannot hold:
`p` is `require("danvim.palette")`, so the colour lives in another file and
same-buffer locals can never reach it. The motivating screenshot is the
cross-file case.

Resolved in favour of "Testing", since that is the feature actually being
asked for. A definition whose value is a colour *table* now carries a `fields`
map, and a member access onto it (`p.steel`) resolves through it. Tables come
from two places:

- one written out in the buffer — `local t = { steel = "#7890a0" }`
- one named by `require("mod")` — read from the **running Neovim's**
  `package.loaded`, not by opening and parsing the other file

The `require` path is why this is not really "cross-file resolution": nothing
reads `palette.lua`. It asks the interpreter for a table it has already loaded.
That keeps the no-LSP, no-file-IO property the design wanted, and costs one
table lookup. Modules not already loaded are only `require`d when listed in the
new `modules` option, because `require` runs arbitrary Lua and doing that
silently on whatever a buffer mentions would be a code-execution footgun.

Measured on `lua/danvim/plugins/style.lua`: 101 swatches, all on `p.<name>`.

### 2. A definition→reference resolver had to be written

The design assumed "Scoping is handled by the locals query itself — no manual
scope-walking needed." Not so: Neovim ships the `locals` *queries* but no
resolver (nvim-treesitter's `locals` module, which had one, is gone on `main`).
`locals.lua` therefore builds the scope tree from `@local.scope` captures,
files each `@local.definition` under its nearest enclosing scope, and resolves
each `@local.reference` by walking outward. Shadowing works as a result.

Consequence for the API: `references_for` takes the analysis object rather than
a bare `def_node`, since the scope map is what makes the answer computable.

### 3. `text.lua`, a module the design did not anticipate

Both passes ask for the text of nearly every node, and
`vim.treesitter.get_node_text` is a buffer round trip each time. Slicing one
cached copy of the lines took `style.lua` from 12.6 ms to 9.1 ms per pass —
comfortably inside the 150 ms debounce, where the original was borderline.

### 4. Smaller things

- Alpha (`#rrggbbaa`, `rgba()`, `hsl(... / a)`) is parsed for acceptance and
  then dropped. A swatch sits on an unknown backdrop, so blending would be a
  guess.
- The literal pass stops descending at the first node whose *whole* text is a
  colour, which is what keeps `a = "#deadbeef"` from matching as well as the
  string inside it. `parse.color_at` is whole-string for this reason.
- `:ColorRefs` takes `on` / `off` / `toggle` (default) / `refresh`.

### Verified

Against the design's three manual cases, live in danvim via the `VIMINIT`
override (`wrapRc = true`, so the repo is not what the installed `nvim` reads):

- `palette.lua` — 25 literal swatches; `style.lua` — 101 reference swatches
- CSS `rgb(120 144 160)` / `hsl(20 70% 62%)` literals; `var()` gets nothing, as
  predicted
- deleting a definition clears its reference swatches on the next debounce

Also covered, beyond the design's list: shadowing (an inner `local a` wins over
an outer one), JS `const`/object members, and the regex fallback on a filetype
with no parser.

### Not done

`flake.nix` still has no entry — the plugin is sourced from `~/Projects` with
`dev = true`, per the design's development-phase instruction. Pushing it to
GitHub and swapping the spec over is the remaining step.
