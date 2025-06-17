local copilot = {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = { enabled = false }, -- disable Copilot's built-in inline UI
      panel = { enabled = false },
    })
  end,
}

return {copilot}
