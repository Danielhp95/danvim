# Kraftnix's neovim configuration

Uses [NixCats](https://github.com/BirdeeHub/nixCats-nvim) to generate Neovim configurations.
  - [NixCats Docs](https://nixcats.org/TOC.html)
  - [NixCats `lazy.nvim` wrapper](https://nixcats.org/nixCats_luaUtils.html)

Currently uses the `lazy.nvim` wrapper.

## Exposed Configurations

There are multiple neovim configurations exposed from this flake:
  - `kraftnvim`: standalone neovim nightly, with bundled lua configuration
  - `kraftnvimLocal`: neovim nightly, uses host lua configuration
  - `kraftnvimStable`: standalone neovim from nixpkgs, with bundled lua configuration
  - `kraftnvimStableLocal`: neovim from nixpkgs, uses host lua configuration

The `Local` flavours of the packages use `$XDG_CONFIG/nvim` by default.
Since neovim 0.9, you can use `$NVIM_APPNAME` to change the location in `$XDG_CONFIG` to use for neovim configuration.

However `nixCats` always sets `NVIM_APPNAME` to whatever is set in `settings.configDirName`.
While this is useful, sometimes you actually want to override this (for maybe testing local changes _not_ in `$XDG_CONFIG/{configDirName}`)
So I added a `KRAFTNVIM_NAME` to overriding the `nixCats` setting at runtime.

Usage:
```sh
git clone https://github.com/kraftnix/kraftnvim ~/.config/kraftnvim-wip
KRAFTNVIM_NAME=kraftnvim-wip kraftnvimLocal
```

## Downstream Usage

Instructions on how to use this configuration in downstream ways.

### Direct Package

Run directly from this flake or add to packages.

```sh
nix run github:kraftnix/kraftnvim#kraftnvim
```

Add to devshell or package

```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [
    inputs.kraftnvim.packages.${pkgs.system}.kraftnvimStable
  ];
}
```

### Home Manager

## Extra Plugins

Extra vim plugins are fetched using `nvfetcher`.

All plugins are added to an overlay at `overlays.vimPlugins` and available as packages
at `packages.<system>.vimPlugins`

### Adding a new Plugin

Add an entry to [`sources.toml`](./packages/sources.toml) and add the plugin to the list at
the top of [`packages`](./packages/default.nix).

### Update `nvfetcher` Plugins

Uses `nvfetcher` to handle extra vimPlugins.

```sh
nvfetcher -c ./packages/sources.toml -o ./packages/_sources
```

## ToDo

- [ ] integrate nixCats splits of categories in lua plugin code
  - currently only splitting for adding plugins, which is ignored by lazy.nvim anyway
- [ ] investigate using `lze` for plugin loading instead of `lazy.nvim`
