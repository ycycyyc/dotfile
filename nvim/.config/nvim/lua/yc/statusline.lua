local api, fn = vim.api, vim.fn

local fileAndNum = "%#StatusLine1# %{expand('%:~:.')}%m%h  %#StatusLine2# %l of %L %#StatusLine3#"
local rfileAndNum = "%=" .. fileAndNum

local originFileAndNum = "%{expand('%:~:.')}%m%h %#StatusLine2# %l of %L "

local M = {
  refresh_count = 0, ---@type number
  max_cost = 0.0, ---@type number
  line = fileAndNum, ---@type string
}

function M.update_line()
  ---@type number
  local cur_buf_is_listed = 0

  local cur_bufnr = api.nvim_get_current_buf() ---@type number
  local abufnr_list = api.nvim_list_bufs() ---@type number[]
  local buflisted = fn.buflisted

  local bufnr_list = {} ---@type number[]
  for _, bufnr in ipairs(abufnr_list) do
    if buflisted(bufnr) == 1 then
      if cur_bufnr == bufnr then
        cur_buf_is_listed = 1
      end
      table.insert(bufnr_list, bufnr)
    end
  end

  if cur_buf_is_listed == 0 then
    return
  end

  local find_cur_buf ---@type nil|number
  local total_len = 0 ---@type number

  ---@type string[]
  local buf_items = {}
  ---@type string
  local nbuffers_str = string.format("%%#NumberBuffers# %d Buffers:", #bufnr_list)

  local width1 = api.nvim_eval_statusline(fileAndNum, { use_tabline = true }).width ---@type number
  local width2 = api.nvim_eval_statusline(nbuffers_str, { use_tabline = true }).width ---@type number
  -- local max_len = vim.o.columns - width1 - width2 - 5 ---@type number
  local max_len = vim.o.columns - width2

  ---@type number[]
  local buf_lens = {}

  local bufname_of = fn.bufname

  for _, bufnr in ipairs(bufnr_list) do
    local sel = "%#StatusLine1#"

    if bufnr == cur_bufnr then
      sel = "%#StatusLineCurFile#"
      find_cur_buf = #buf_items + 1
    end

    local bufname = bufname_of(bufnr)
    local filename = fn.fnamemodify(bufname, ":t") ---@type string
    if bufname == "" then
      filename = "[no name]"
    end

    if bufnr == cur_bufnr then
      filename = originFileAndNum
    end

    local item = string.format(" %%%dT%s %d %s ", bufnr, sel, bufnr, filename)
    local l = api.nvim_eval_statusline(item, { use_tabline = true }).width

    table.insert(buf_items, item)
    table.insert(buf_lens, l)
    total_len = total_len + l

    if find_cur_buf ~= nil and total_len > max_len then
      break
    end
  end

  if find_cur_buf ~= nil and total_len > max_len then
    local items_len = #buf_items

    local l = find_cur_buf ---@type number
    local r = find_cur_buf ---@type number
    local sz = buf_lens[find_cur_buf]

    while l ~= 1 or r ~= items_len do
      if r + 1 <= items_len then
        if sz + buf_lens[r + 1] > max_len then
          break
        end
        r = r + 1
        sz = sz + buf_lens[r]
      end

      if l - 1 >= 1 then
        if sz + buf_lens[l - 1] > max_len then
          break
        end
        l = l - 1
        sz = sz + buf_lens[l]
      end
    end

    M.line = nbuffers_str .. table.concat(buf_items, "", l, r) .. "%#TabLineFill#" --.. rfileAndNum
  else
    table.insert(buf_items, 1, nbuffers_str)
    table.insert(buf_items, "%#TabLineFill#")
    -- table.insert(buf_items, rfileAndNum)
    M.line = table.concat(buf_items)
  end
end

M.refresh = function()
  local start = vim.fn.reltime()

  M.update_line()

  M.refresh_count = M.refresh_count + 1
  local cost = vim.fn.reltimestr(vim.fn.reltime(start))

  if tonumber(cost) > M.max_cost then
    M.max_cost = tonumber(cost)
  end
end

M.setup = function()
  vim.opt.laststatus = 3

  -- create statueline theme
  vim.cmd [[
      hi! StatusLine1 ctermfg=145 ctermbg=239

      hi! StatusLineCurFile ctermfg=235 ctermbg=114 cterm=bold
      hi! StatusLine2 ctermfg=235 ctermbg=114 cterm=bold

      hi! StatusLine3 ctermfg=145 ctermbg=236
      hi! NumberBuffers ctermfg=235 ctermbg=39 cterm=bold
      hi! WinSeparator ctermbg=237
      augroup nobuflisted
        autocmd!
        autocmd FileType qf set nobuflisted
        autocmd FileType fugitive set nobuflisted
      augroup END
  ]]

  api.nvim_create_autocmd({ "BufEnter", "BufDelete" }, {
    callback = function()
      M.refresh()
    end,
  })

  api.nvim_create_user_command("ShowStatuslineStat", function()
    vim.print("[StatusLine] refresh cnt:" .. M.refresh_count .. " max cost:" .. M.max_cost)
  end, {})

  function _G.yc_statusline()
    return M.line
  end

  vim.opt.statusline = "%!v:lua.yc_statusline()"
end

return M
