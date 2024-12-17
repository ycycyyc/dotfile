local blink = {
  "saghen/blink.cmp",
  config = require("plugin.blink").config,
}

local cmp = {
  "hrsh7th/nvim-cmp",
  config = require("plugin.cmp").config,
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
  },
}

local plugins = {
  blink = blink,
  cmp = cmp,
}
return plugins[YcVim.env.cmp]
