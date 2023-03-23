local M = {}
M.config = function()
  -- require'FTerm'.setup({border = 'double', dimensions = {width = 0.8, height = 0.8}})
  --
  -- -- Example keybindings
  --
  -- map('n', '<C-t>', '<CMD>lua require("FTerm").toggle()<CR>', opts)
  -- map('t', '<C-t>', '<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>', opts)
  local keys = require "basic.keys"
  require("toggleterm").setup {
    -- size can be a number or function which is passed the current terminal
    -- size = 20,
    size = function(term)
      if term.direction == "horizontal" then
        return 20
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    open_mapping = keys.toggle_term,
    -- on_open = fun(t: Terminal), -- function to run when the terminal opens
    -- on_close = fun(t: Terminal), -- function to run when the terminal closes
    hide_numbers = true, -- hide the number column in toggleterm buffers
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = "1", -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
    start_in_insert = true,
    insert_mappings = false, -- whether or not the open mapping applies in insert mode
    terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
    persist_size = true,
    -- direction can be 'vertical', 'horizontal', 'window', 'float'
    direction = "float",
    close_on_exit = true, -- close the terminal window when the process exits
    shell = vim.o.shell, -- change the default shell
    -- This field is only relevant if direction is set to 'float'

    -- Only for floating mode <<<
    -- float_opts = {
    --   -- The border key is *almost* the same as 'nvim_open_win'
    --   -- see :h nvim_open_win for details on borders however
    --   -- the 'curved' border is a custom border type
    --   -- not natively supported but implemented in this plugin.
    --   border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
    --   width = <value>,
    --   height = <value>,
    --   winblend = 3,
    --   highlights = {
    --     border = "Normal",
    --     background = "Normal",
    --   }
    -- }
    -- >>>
  }
end
return M
