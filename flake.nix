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
      inputs.nixpkgs.follows = "nixpkgs";
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
              luau-lsp  # luau lsp
              vscode-langservers-extracted # HTML/CSS/JSON/ESLint
              nixd # nix
              bash-language-server # bash
              ty # python

              claude-agent-acp
              claude-code

              marksman # markdown
              texlab # LaTex

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
              python312Packages.pylatexenc # for rendering latex in render-markdown plugin
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
              gitlinker-nvim # open/copy external git forge links (GBrowse replacement)
              gitsigns-nvim # git signs in the columns  (TODO: look more things in this plugin)
              diffview-nvim # Diif/Merge view UI
              octo-nvim # GitHub issues/PRs/reviews as buffers (uses `gh`, see lspsAndRuntimeDeps)

              # Completion
              colorful-menu-nvim # Better tresitter integration in completion engine
              diffs-nvim

              firenvim # embed neovim in browser text areas (needs Firenvim browser extension)

              ## LSP
              # TODO(add back)
              # nvim-lspconfig # Top level LSP configuratio
              fidget-nvim
              lazydev-nvim # Lua nvim API types (replaces neodev)

              ## UI
              lualine-nvim # status line!
              which-key-nvim
              bufferline-nvim
              trouble-nvim
              yazi-nvim

              # Library
              snacks-nvim

              nvim-bqf # TODO: learn this!

              ## Treesitter
              nvim-treesitter-textobjects # conceals top part of screen in deeply nested code
              nvim-treesitter-context # conceals top part of screen in deeply nested code

              # AI
              # avante-nvim
              claudecode-nvim # coder/claudecode.nvim: drive the real `claude` CLI in-editor
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
                one-small-step-for-vimkind-nvim # lua dap adapter
                telescope-dap-nvim # telescope picker for DAP
                nvim-dap-python # python dap adapter
              ];
            };
            colorscheme = with pkgs.vimPlugins; [
              onedarkpro-nvim
              catppuccin-nvim
            ];
            markdown = with pkgs.vimPlugins; [
              markdown-preview-nvim
            ];
            general = {
              ui = with pkgs.vimPlugins; [
                ## Lib
                plenary-nvim # toolbox/lib for many libs

                ## UI
                dressing-nvim # pretty/glossy vim.ui.{select|input}
                nvim-web-devicons # nerd fonts for nvim
                noice-nvim # floating cmdline popup (top-center)
                nui-nvim # UI library (required by noice)
              ];
              blink = with pkgs.vimPlugins; [
                # blink completion engine
                # blink-cmp  Too old in nixpkgs
                blink-copilot
                blink-cmp-git
                blink-cmp-avante
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
              telescope = with pkgs.vimPlugins; [
                telescope-nvim
                telescope-fzf-native-nvim
                telescope-file-browser-nvim
                telescope-manix # nix manix search
                telescope-undo-nvim
              ];
              always = with pkgs.vimPlugins; [
                # misc
                fzf-vim # another fuzzy search tool/picker
                pkgs.fzf # for above

                # Movement / buffer management
                flash-nvim # jump around with f,t,s
                harpoon # mark buffers and jump between them
              ];
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
        gitPlugins = true;
        customPlugins = true;
        test = true;
        telescope = true;
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
            settings.neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
