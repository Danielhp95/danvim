-- TODO: ADD BLINK compatibility
return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  opts = {
    provider = 'ollama',
    ollama = {
      model = 'phi4:14b',
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- build = 'make',
  build = 'make BUILD_FROM_SOURCE=true',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'echasnovski/mini.pick', -- for file_selector provider mini.pick
    'nvim-telescope/telescope.nvim', -- for file_selector provider telescope
    'ibhagwan/fzf-lua', -- for file_selector provider fzf
    'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
    'zbirenbaum/copilot.lua', -- for providers='copilot'
    {
      -- support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
        },
        rag_service = {
          enabled = true, -- Enables the RAG service
          host_mount = os.getenv 'HOME', -- Host mount path for the rag service
          provider = 'ollama', -- The provider to use for RAG service (e.g. openai or ollama)
          llm_model = 'phi4:14b', -- The LLM model to use for RAG service
          embed_model = 'omic-embed-text', -- The embedding model to use for RAG service. (default)
          endpoint = 'http://localhost:11434', -- The API endpoint for RAG service
        },
      },
    },
  },
}
