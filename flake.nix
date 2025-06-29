{
  description = "My Neovim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.11";

    nixCats.url = "github:BirdeeHub/nixCats-nvim?rev=fa33abe592eb084044e12e9d1e1b6870364a75f9";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
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
        # allowUnfree = true;
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
              vscode-langservers-extracted # HTML/CSS/JSON/ESLint
              nixd # nix
              bash-language-server # bash
              basedpyright # python
              ty # python
              pyrefly # python
              marksman # markdown
              texlab # LaTex

              nodePackages.yaml-language-server # yaml
              nodePackages.dockerfile-language-server-nodejs # dockerfile
              nodePackages.typescript-language-server # typescript

              libgit2
              cargo

              gh # GitHub CLI, for octo-nvim

              ripgrep
              git
              fd
              stdenv.cc.cc
              nix-doc
              manix

              python312Packages.pylatexenc # for rendering latex in render-markdown plugin
              tectonic # Fore rendering latex equations (snacks.nvim)

              nodejs

              # Formatters
              stylua
              yamlfmt
              ruff
              nixfmt-rfc-style

              # TESTING
              fzf
            ];
          };

          startupPlugins = with pkgs.vimPlugins; {
            dani = [
              nvim-autopairs # pair up brackets/quotes etc.
              nvim-surround # autopairs ()[]<>{} completion (with treesitter magic)
              comment-nvim
              undotree

              ## Git
              vim-fugitive # tpope git core plugin
              gitlinker-nvim # open/copy external git forge links (GBrowse replacement)
              gitsigns-nvim # git signs in the columns  (TODO: look more things in this plugin)
              diffview-nvim # Diif/Merge view UI
              octo-nvim # GitHub CLI integration for neovim

              # Completion
              colorful-menu-nvim # Better tresitter integration in completion engine

              ## LSP
              # TODO(add back)
              # nvim-lspconfig # Top level LSP configuratio
              fidget-nvim
              neodev-nvim # Lua LS

              ## UI
              lualine-nvim # status line!
              which-key-nvim
              inputs.stable.legacyPackages.x86_64-linux.vimPlugins.wilder-nvim # Remove in favour of noice
              cpsm # needed for wilder
              nvim-colorizer-lua
              indent-blankline-nvim
              bufferline-nvim
              trouble-nvim
              yazi-nvim

              # Library
              snacks-nvim

              ## General
              sqlite-lua
              toggleterm-nvim
              vim-floaterm
              term-edit-nvim

              nvim-bqf # TODO: learn this!

              ## Treesitter
              nvim-treesitter-textobjects
              nvim-treesitter-context # conceals top part of screen in deeply nested code
              nvim-ts-context-commentstring # add commentstring context to treesitter
              nvim-treesitter-refactor # smart rename (current scope) + highlight scope + backup go to def/ref

              # AI
              # avante-nvim
              copilot-lua
              blink-copilot

            ];
            general = [
              ## Lib
              plenary-nvim # toolbox/lib for many libs
              lazy-nvim

              oil-nvim

              ## UI
              lualine-nvim # status/tabline
              dressing-nvim # pretty/glossy vim.ui.{select|input}
              nvim-web-devicons # nerd fonts for nvim
              nvim-colorizer-lua # highlight hex codes with their colour
              noice-nvim # meta UI plugin, message routing, lsp, cmdline, etc.
              nui-nvim # UI library (noice + dap-ui)
              nvim-notify # notification handler (used by noice)
              urlview-nvim # picker (ui.select support) for URLs

              ## LSP
              # nvim-lspconfig # configure LSPs
              neodev-nvim # configure lua + neovim projects
              lsp_signature-nvim # LSP Signature Info (old, noice instead)
            ];
            format = with pkgs.vimPlugins; [
              conform-nvim
            ];
          };

          # in `lazy.nvim` setup, this is the same as `startupPlugins`
          optionalPlugins = {
            debug = with pkgs.vimPlugins; {
              # it is possible to add default values.
              # there is nothing special about the word "default"
              # but we have turned this subcategory into a default value
              # via the extraCats section at the bottom of categoryDefinitions.
              default = [
                ## Dap
                nvim-dap # Debug Adapter Protocol
                nvim-dap-ui # nui based ui for DAP
                nvim-nio # required by nvim-dap-ui
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
              blink = with pkgs.vimPlugins; [
                # blink completion engine
                # blink-cmp  Too old in nixpkgs
                blink-copilot
                blink-cmp-git
                blink-cmp-avante
                blink-emoji-nvim
                friendly-snippets
              ];
              treesitter = with pkgs.vimPlugins; [
                nvim-treesitter-textobjects # move/swap/peek/select objects
                nvim-treesitter-textsubjects # select textsubjects up/down
                rainbow-delimiters-nvim # fancy rainbow brackets

                nvim-treesitter.withAllGrammars
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
            # settings.neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
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
          shellHook = '''';
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
