{ inputs, lib, ... }:
let
  inherit (lib)
    mapAttrs
    ;

  getPkgs = system: inputs.nixpkgs.legacyPackages.${system};

  replaceDots = mapAttrs (name: plugin: plugin // {
    # required for lazy-loading to work properly for downstreams
    pname = plugin.src.repo;
  });

  allVimPlugins =
    nixpkgs: sources:
    (import ./vim-plugin.nix nixpkgs sources [
      # "nvim-nu"
      "nvim-telescope-hop"
      "nvim-guess-indent"
      "sessions-nvim"
      "fm-nvim"
      "portal-nvim"
      "magma-nvim"
      "vim-doge"
      "one-small-step-for-vimkind-nvim"
      "telescope-menufacture"
      "telescope-env"
      "telescope-changes"
      "telescope-luasnip"
      "telescope-lazy-nvim"
      "cmp-nixpkgs"
      "easypick-nvim"
      "terminal-nvim"
      "browser-bookmarks-nvim"
      "middleclass-nvim"
      "nvim-devdocs"
    ]);
  getVimSources = prev: replaceDots (prev.callPackage (import ./_sources/generated.nix) { });
  vimPlugins = final: prev: allVimPlugins prev (getVimSources final);
  systems = [ "x86_64-linux" ];
in
{
  overlays = {
    vimPlugins = final: prev: {
      vimPluginsSources = getVimSources prev;
      vimPlugins = prev.vimPlugins // (vimPlugins final prev);
    };
  };

  vimPlugins = lib.genAttrs systems (system: vimPlugins (getPkgs system) (getPkgs system));
}
