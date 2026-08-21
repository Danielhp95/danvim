{
  description = "My Neovim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-26.05";

    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    neovim-nightly-overlay = {
      type = "git";
      url = "https://github.com/nix-community/neovim-nightly-overlay";
      # rev = "80b1f16dba171a70c44c2ee6ec9529876152a7f5";
      # No nixpkgs.follows: building neovim against the overlay's own locked
      # nixpkgs is what makes the nix-community cache hit; following ours
      # meant compiling neovim locally on every nightly bump.
    };

    # Local, unpublished plugin under active development; picked up by
    # standardPluginOverlay (see `dependencyOverlays` below) as
    # `pkgs.neovimPlugins.color-refs`.
    plugins-color-refs = {
      url = "path:/home/dani/Projects/color-refs.nvim";
      flake = false;
    };
  };

  # see :help nixCats.flake.outputs
  outputs =
    {
      self,
      nixpkgs,
      nixCats,
      ...
    }@inputs:
    let
      inherit (nixCats) utils;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      luaPath = "${./.}";
      forEachSystem = utils.eachSystem systems;
      # will not apply to module imports
      extra_pkg_config = {
        # Needed for unfree packages in runtime deps (claude-code)
        allowUnfree = true;
      };

      packages = import ./packages {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };

      # see :help nixCats.flake.outputs.overlays
      dependencyOverlays = [
        packages.overlays.vimPlugins
        # This overlay grabs all the inputs named in the format
        # `plugins-<pluginName>`
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a set of our plugins.
        (utils.standardPluginOverlay inputs)
      ];

      # see :help nixCats.flake.outputs.categories
      #     :help nixCats.flake.outputs.categoryDefinitions.scheme
      categoryDefinitions =
        {
          pkgs,
          settings,
          categories,
          extra,
          name,
          mkNvimPlugin,
          ...
        }@packageDef:
        {
          # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

          lspsAndRuntimeDeps = with pkgs; {
            general = [
              lua-language-server # lua
              luau-lsp # luau lsp
              vscode-langservers-extracted # HTML/CSS/JSON/ESLint
              nixd # nix
              bash-language-server # bash
              ty # python

              claude-agent-acp
              claude-code

              marksman # markdown
              texlab # LaTex

              elan

              yaml-language-server # yaml
              docker-language-server
              typescript-language-server # typescript

              libgit2
              cargo

              gh # GitHub CLI, for octo-nvim

              television # for television.nvim

              ripgrep
              git
              fd
              stdenv.cc.cc
              nix-doc
              manix

              yazi
              bat
              file # needed for codecompanion
              wordnet # `wn` CLI backing blink-cmp-words dictionary source

              gnumake # needed for avante
              python312Packages.pylatexenc # latex2text; unused while render-markdown's
              # latex handler is off (snacks.image renders equations instead) -- kept so
              # flipping `latex.enabled = true` in style.lua just works.
              tectonic # Fore rendering latex equations (snacks.nvim)
              imagemagick # `magick`/`convert` for snacks.image (inline PNGs in markdown)
              ghostscript # `gs` — ImageMagick's delegate for rasterizing PDF pages (snacks.image)
              ffmpeg # ImageMagick's `video:decode` delegate — extracts a frame from mp4/mkv/webm (snacks.image)

              nodejs

              # Formatters
              stylua
              yamlfmt
              ruff
              nixfmt
              jq

              # TESTING
              fzf
              python313Packages.pytest
            ];
          };

          startupPlugins = with pkgs.vimPlugins; {
            # NOTE: with the lazy.nvim wrapper, plugins in `start` are sourced
            # natively at startup *in addition* to being managed by lazy.nvim,
            # which defeats every event/cmd/keys lazy-loading trigger. Only
            # lazy.nvim itself (bootstrap) and the treesitter grammars belong
            # here; everything else goes in optionalPlugins (the `opt` dir),
            # where lazy.nvim's dev.path resolver picks them up.
            general = [
              lazy-nvim
            ];
            # Treesitter parsers - loaded at startup to ensure all grammars are available
            treesitter = [
              # NOTE: withAllGrammars doesn't work reliably - parsers not found by Neovim
              # Keeping commented for future testing:
              nvim-treesitter.withAllGrammars
              ((pkgs.neovimUtils.grammarToPlugin pkgs.tree-sitter-grammars.tree-sitter-python).overrideAttrs {
                installQueries = true;
              })
            ];
          };

          # Under the lazy.nvim wrapper these are resolved by lazy's dev.path,
          # so loading is governed entirely by the lua plugin specs.
          optionalPlugins = {
            dani = with pkgs.vimPlugins; [
              nvim-autopairs # pair up brackets/quotes etc.
              nvim-surround # autopairs ()[]<>{} completion (with treesitter magic)
              undotree

              ## Git
              vim-fugitive # tpope git core plugin
              # NOTE: no gitlinker here — nixpkgs still packages ruifm's abandoned
              # original, so the maintained linrongbin16 fork is lazy-cloned
              # instead (see git.lua).
              gitsigns-nvim # git signs in the columns  (TODO: look more things in this plugin)
              # Maintained fork; sindrets/diffview.nvim's last commit was 2024-06-13.
              # Drop-in: same commands, same opts, CI runs on nightly.
              diffview-plus-nvim # Diif/Merge view UI
              octo-nvim # GitHub issues/PRs/reviews as buffers (uses `gh`, see lspsAndRuntimeDeps)
              vim-flog # git branch/commit graph browser, drives fugitive

              # Completion
              colorful-menu-nvim # Better tresitter integration in completion engine
              diffs-nvim

              firenvim # embed neovim in browser text areas (needs Firenvim browser extension)

              ## LSP
              nvim-lspconfig # Top level LSP configuration
              fidget-nvim
              lazydev-nvim # Lua nvim API types (replaces neodev)

              ## UI
              lualine-nvim # status line!
              which-key-nvim
              bufferline-nvim
              trouble-nvim
              yazi-nvim
              render-markdown-nvim # in-buffer markdown rendering (see style.lua)
              codediff-nvim # side-by-side diff UI behind :CodeDiff (needs nui)

              # Library
              snacks-nvim

              pkgs.neovimPlugins.color-refs # colour swatches at variable references

              nvim-bqf # TODO: learn this!

              lean-nvim # Lean 4 support (needs `elan`, see lspsAndRuntimeDeps)

              ## Treesitter
              nvim-treesitter-textobjects # conceals top part of screen in deeply nested code
              nvim-treesitter-context # conceals top part of screen in deeply nested code

              # AI
              # avante-nvim
              claudecode-nvim # coder/claudecode.nvim: drive the real `claude` CLI in-editor
              # olimorris/codecompanion.nvim: chat + inline editing against the
              # local ollama server. Deliberately light -- plenary and
              # treesitter are its only deps and both are already here, and
              # unlike avante it builds no native component.
              codecompanion-nvim
              # inputs.stable.legacyPackages.x86_64-linux.vimPlugins.copilot-lua
              copilot-lua
            ];
            format = with pkgs.vimPlugins; [
              conform-nvim
            ];
            debug = with pkgs.vimPlugins; {
              # it is possible to add default values.
              # there is nothing special about the word "default"
              # but we have turned this subcategory into a default value
              # via the extraCats section at the bottom of categoryDefinitions.
              default = [
                ## Dap
                nvim-dap # Debug Adapter Protocol
                nvim-dap-view # minimal modern DAP UI
                nvim-nio # required by nvim-dap-view
                nvim-dap-virtual-text # UI / Highlight for DAP virtual text
                nvim-dap-python # python dap adapter
              ];
            };
            markdown = with pkgs.vimPlugins; [
              # Browser preview for markdown/HTML/AsciiDoc/SVG. Replaced
              # markdown-preview-nvim, whose upstream has been dormant since
              # 2023-10 (last tag 2022), so nixpkgs could only ever ship a
              # three-year-old snapshot of it. This one is pure Lua -- no node
              # bundle, no build step -- and nixpkgs tracks its current tag.
              #
              # Pinned past v0.9.6: that tag's Server:start ends in `uv.run()`,
              # which runs libuv's loop to completion -- but inside Neovim that
              # loop is already Neovim's own, so it never returns and the editor
              # freezes on :LivePreview (upstream #362, fixed 2026-03-05). No
              # release has been cut since, so the tag nixpkgs packages is still
              # the broken one. Drop the override once a tag > v0.9.6 lands.
              (live-preview-nvim.overrideAttrs {
                version = "0.9.6-unstable-2026-07-21";
                src = pkgs.fetchFromGitHub {
                  owner = "brianhuster";
                  repo = "live-preview.nvim";
                  rev = "a30e54e51e7480d7060c8c8185f2a963ad3518b4";
                  hash = "sha256-k88cp5kvlfc/9H02PMjEJ4kYgTt5xDIhq9RxspeSAMA=";
                };
              })
            ];
            general = {
              ui = with pkgs.vimPlugins; [
                ## Lib
                plenary-nvim # toolbox/lib for many libs

                ## UI
                dressing-nvim # pretty/glossy vim.ui.{select|input}
                nvim-web-devicons # nerd fonts for nvim
                tiny-cmdline-nvim # floating cmdline popup (top-center), repositions ui2's own window
                nui-nvim # UI library (required by codediff)
                mini-icons # icon provider render-markdown auto-detects first
                tiny-devicons-auto-colors-nvim # recolours devicons to the Ember palette
              ];
              blink = with pkgs.vimPlugins; [
                # blink completion engine. blink-cmp itself is not listed: the
                # sources below already pull it in as a dependency, so nix puts
                # it in `start` regardless.
                blink-copilot
                blink-emoji-nvim
                blink-ripgrep-nvim
                blink-cmp-spell # spell suggestions from Neovim's spellcheck
                blink-cmp-words # dictionary/thesaurus source (needs `wn` from wordnet)
                blink-nerdfont-nvim # Nerd Font icon completion (trigger ":")
                blink-cmp-env # environment variable ($VAR) completion
                friendly-snippets
              ];
              treesitter = with pkgs.vimPlugins; [
                # Nushell parser (not included in withAllGrammars)
                ((pkgs.neovimUtils.grammarToPlugin pkgs.tree-sitter-grammars.tree-sitter-nu).overrideAttrs {
                  installQueries = true;
                })
              ];
              # Emptied by the 2026-08 dead-weight pass: fzf-vim, harpoon and
              # one-small-step-for-vimkind were shipped here with no lazy spec
              # anywhere, so lazy never loaded them; flash-nvim's spec is
              # commented out in essentials.lua. Re-adding any of them means
              # re-adding its spec too, or it lands back in `opt` unused.
              # (`pkgs.fzf` went with fzf-vim, but the fzf *binary* is still on
              # nvim's PATH via lspsAndRuntimeDeps above.)
              always = with pkgs.vimPlugins; [ ];
            };
          };

          # shared libraries to be added to LD_LIBRARY_PATH
          # variable available to nvim runtime
          sharedLibraries = {
            general = with pkgs; [
              libgit2
            ];
          };

          # environmentVariables:
          # this section is for environmentVariables that should be available
          # at RUN TIME for plugins. Will be available to path within neovim terminal
          environmentVariables = {
            test = {
              # CATTESTVAR = "It worked!";
            };
          };

          # If you know what these are, you can provide custom ones by category here.
          # If you dont, check this link out:
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
          extraWrapperArgs = {
            local = [
              # NOTE(workaround): wrapper script from nixCats sets NVIM_APPNAME=nvim, nullifying runtime overrides
              # instead you can set $KRAFTNVIM_NAME to override the NVIM_APPNAME
              # useful for local testing
              ''--run 'export NVIM_APPNAME="''${KRAFTNVIM_NAME:-$NVIM_APPNAME}"' ''
            ];
          };

          # lists of the functions you would have passed to
          # python.withPackages or lua.withPackages

          # get the path to this python environment
          # in your lua config via
          # vim.g.python3_host_prog
          # or run from nvim terminal via :!<packagename>-python3
          extraPython3Packages = {
            test = (_: [ ]);
          };
          # populates $LUA_PATH and $LUA_CPATH
          extraLuaPackages = {
            test = [ (_: [ ]) ];
          };
        };

      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.

      # and a set of categories that you want
      # (and other information to pass to lua)
      categories = {
        dani = true;
        general = true;
        format = true;
        markdown = true;
        gitPlugins = true;
        customPlugins = true;
        test = true;
        treesitter = true;
        debug = true;
        blink = true;
        always = true;
        have_nerd_font = true;
      };
      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        nvim =
          { pkgs, ... }@args:
          {
            # see :help nixCats.flake.outputs.settings
            settings.wrapRc = true;
            settings.configDirName = "nvim";
            # TODO(dani): uncomment when neovim-unwrapped gets maintainer
            settings.neovim-unwrapped =
              inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
            categories = categories // {
              configDirName = "nvim";
            };
          };
        nvimStable =
          { ... }:
          {
            settings.wrapRc = true;
            settings.configDirName = "nvim";
            categories = categories // {
              configDirName = "nvim";
            };
          };
        nvimStableLocal =
          { ... }:
          {
            settings.wrapRc = false;
            # settings.configDirName = "kraftnvimStable";
            categories = categories // {
              local = true;
            };
          };
      };
      defaultPackageName = "nvim";
    in
    # NOTE: BOILERPLATE BELOW
    forEachSystem (
      system:
      let
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit
            nixpkgs
            system
            dependencyOverlays
            extra_pkg_config
            ;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;
        pkgs = import nixpkgs { inherit system; };
      in
      {
        vimPlugins = packages.vimPlugins.${system};
        packages = utils.mkAllWithDefault defaultPackage;
        devShells.default = pkgs.mkShell {
          name = defaultPackageName;
          packages = [
            defaultPackage
            pkgs.nvfetcher
          ];
          inputsFrom = [ ];
          shellHook = "";
        };
        checks = self.packages.${system} // self.vimPlugins.${system};
      }
    )
    // (
      let
        # we also export a nixos module to allow reconfiguration from configuration.nix
        nixosModule = utils.mkNixosModules {
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
        # and the same for home manager
        homeModule = utils.mkHomeModules {
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
      in
      {
        overlays =
          utils.makeOverlays luaPath {
            inherit nixpkgs dependencyOverlays extra_pkg_config;
          } categoryDefinitions packageDefinitions defaultPackageName
          // packages.overlays;

        nixosModules.default = nixosModule;
        homeModules.default = homeModule;

        inherit utils nixosModule homeModule;
        passthru = {
          inherit
            packageDefinitions
            categoryDefinitions
            luaPath
            defaultPackageName
            extra_pkg_config
            nixpkgs
            dependencyOverlays
            ;
        };
        inherit (utils) templates;
      }
    );
}
