{
  description = "My Neovim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.11";

    nixCats.url = "github:BirdeeHub/nixCats-nvim";
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
              ### TODO: under progress
              # For avante-nvim
              pkg-config
              openssl
              makeWrapper
              perl
              # rustup
              gcc
              rustc
              gnumake
              ###

              lua-language-server
              vscode-langservers-extracted

              nixd
              gopls
              stylua
              yamlfmt
              nixfmt-rfc-style
              bash-language-server
              basedpyright

              nodejs_22 # for sourcegraph
              nodePackages.yaml-language-server
              nodePackages.dockerfile-language-server-nodejs
              docker-compose-language-service
              libgit2
              nodePackages.typescript-language-server
              marksman
              texlab
              cargo

              ripgrep
              git
              fd
              stdenv.cc.cc
              nix-doc
              manix

              python312Packages.pylatexenc # for rendering latex in render-markdown plugin
              tectonic  # Fore rendering latex equations (snacks.nvim)
            ];
          };

          startupPlugins = with pkgs.vimPlugins; {
            dani = [
              lazy-nvim
              nvim-autopairs
              nvim-surround
              comment-nvim
              undotree
              nvim-tree-lua

              # Colorscheme
              dracula-nvim

              ## Git
              diffview-nvim

              ## random
              firenvim

              ## LSP
              nvim-lspconfig # Top level LSP configuratio
              fidget-nvim
              neodev-nvim # Lua LS
              lsp_signature-nvim # Show function signatur

              ## UI
              plenary-nvim
              lualine-nvim
              which-key-nvim
              inputs.stable.legacyPackages.x86_64-linux.vimPlugins.wilder-nvim
              cpsm
              nvim-web-devicons
              nvim-colorizer-lua
              indent-blankline-nvim
              bufferline-nvim
              trouble-nvim
              yazi-nvim

              snacks-nvim

              ## Git
              gitlinker-nvim
              gitsigns-nvim

              ## General
              sqlite-lua
              vim-oscyank
              toggleterm-nvim
              vim-floaterm
              term-edit-nvim

              vim-togglelist
              nvim-bqf
              pkgs.fzf
              zk-nvim

              # Note taking
              obsidian-nvim

              ## Treesitter
              nvim-treesitter-textobjects
              nvim-treesitter-context
              nvim-treesitter-refactor

              # AI
              # avante-nvim
            ];
            general = [
              ## Lib
              plenary-nvim # toolbox/lib for many libs
              middleclass-nvim # smarter class implementation
              tokyonight-nvim
              lazy-nvim

              oil-nvim
              nvim-web-devicons

              ## UI
              lualine-nvim # status/tabline
              dressing-nvim # pretty/glossy vim.ui.{select|input}
              nvim-web-devicons # nerd fonts for nvim
              nvim-colorizer-lua # highlight hex codes with their colour
              noice-nvim # meta UI plugin, message routing, lsp, cmdline, etc.
              nui-nvim # UI library (noice + dap-ui)
              nvim-notify # notification handler (used by noice)
              tabline-nvim # tabline (old, replaced by lualine)
              zen-mode-nvim # remove distractions
              urlview-nvim # picker (ui.select support) for URLs

              ## LSP
              nvim-lspconfig # configure LSPs
              neodev-nvim # configure lua + neovim projects
              nvim-nu # old-school null-ls nushell LSP
              none-ls-nvim # none-ls (language agnostic LSP)
              lsp_signature-nvim # LSP Signature Info (old, noice instead)
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
              onedark-nvim
              nightfox-nvim
            ];
            lint = with pkgs.vimPlugins; [
              nvim-lint
            ];
            format = with pkgs.vimPlugins; [
              conform-nvim
            ];
            markdown = with pkgs.vimPlugins; [
              markdown-preview-nvim
            ];
            neonixdev = with pkgs.vimPlugins; [
              lazydev-nvim
            ];
            general = {
              terminal = with pkgs.vimPlugins; [
                terminal-nvim # toggle terminals
              ];
              cmp = with pkgs.vimPlugins; [
                ## cmp
                blink-cmp # nvim-cmp replacement
                nvim-cmp
                cmp-cmdline
                cmp-buffer
                cmp-path
                cmp-rg
                cmp_luasnip
                cmp-latex-symbols
                luasnip
                cmp-nvim-lsp
                friendly-snippets
                lspkind-nvim
              ];
              treesitter = with pkgs.vimPlugins; [
                nvim-treesitter-textobjects # move/swap/peek/select objects
                nvim-treesitter-textsubjects # select textsubjects up/down
                nvim-treesitter-context # conceals top part of screen in deeply nested code
                nvim-treesitter-refactor # smart rename (current scope) + highlight scope + backup go to def/ref
                nvim-ts-context-commentstring # add commentstring context to treesitter
                rainbow-delimiters-nvim # fancy rainbow brackets
                playground

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
                fzf-lua # another fuzzy search tool/picker
                pkgs.fzf # for above
                comment-nvim # comments with easy motion
                todo-comments-nvim # highlight comments

                # git
                vim-fugitive # tpope git core plugin
                gitlinker-nvim # open/copy external git forge links (GBrowse replacement)
                gitsigns-nvim # git signs in the columns
                diffview-nvim # Diif/Merge view UI

                # Movement / buffer management
                treesj # fancy split/join of TS objects
                nvim-autopairs # pair up brackets/quotes etc.
                nvim-surround # easily change pairs (i.e. "" -> '')
                flash-nvim # jump around with f,t,s
                harpoon # mark buffers and jump between them
                portal-nvim # jump around lists with keys
                neoscroll-nvim # animated/speed scrolling (laggy over SSH tho)
                nvim-surround # autopairs ()[]<>{} completion (with treesitter magic)
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
        cmp = true;
        cmpCmdline = true;
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
            settings.neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            categories = categories // {
              configDirName = "nvim";
            };
          };
        nvimLocal =
          { pkgs, ... }:
          {
            settings.wrapRc = false;
            # settings.configDirName = "nvim";
            settings.neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            categories = categories // {
              local = true;
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
