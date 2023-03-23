-- install lsp-server from
-- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
local key_on_attach = require("utils.lsp").key_on_attach
local env = require "basic.env"

local M = {}

-- conf key binding
--
M.load_lsp_config = function()
  -- 0. base cofig
  local lspconfig = require "lspconfig"
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true

  vim.lsp.set_log_level "OFF"
  vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { underline = false })

  -- 1. lua
  -- /lib64/libm.so.6.old remember that
  -- https://www.chrisatmachine.com/Neovim/28-neovim-lua-development/
  USER = vim.fn.expand "$USER"

  local sumneko_root_path = env.lua_ls_root
  local sumneko_binary = env.lua_ls_bin

  local runtime_path = vim.split(package.path, ";")
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  lspconfig.lua_ls.setup {
    on_attach = key_on_attach(),
    cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT",
          -- Setup your lua path
          path = runtime_path,
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { "vim" },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
      },
    },
  }

  -- 2. gopls
  lspconfig.gopls.setup {
    on_attach = key_on_attach(),
    capabilities = capabilities,
    cmd = { "gopls", "serve" },
    settings = {
      gopls = {
        experimentalPostfixCompletions = true,
        analyses = {
          unusedparams = true,
          shadow = true,
          nilness = true,
          printf = true,
          unusedwrite = true,
          fieldalignment = false,
        },
        staticcheck = true,
      },
    },
    commands = {
      GoImportAndFormat = {
        function()
          require("utils.lsp").go_import()
        end,
      },
    },
    root_dir = function()
      return vim.fn.getcwd()
    end,
  }

  -- 3. clangd
  local function switch_source_header_splitcmd(bufnr, splitcmd)
    bufnr = lspconfig.util.validate_bufnr(bufnr)
    local params = { uri = vim.uri_from_bufnr(bufnr) }
    vim.lsp.buf_request(bufnr, "textDocument/switchSourceHeader", params, function(err, dst_file, result)
      if err then
        error(tostring(err))
      end
      if not result then
        print "Corresponding file can’t be determined"
        return
      end
      vim.api.nvim_command(splitcmd .. " " .. vim.uri_to_fname(dst_file))
    end)
  end

  local clangd_bin = env.clangd_bin

  lspconfig.clangd.setup {
    on_attach = key_on_attach { diable_format = true },
    cmd = {
      clangd_bin,
      "--background-index",
      "--suggest-missing-includes", -- 在后台自动分析文件（基于complie_commands)
      -- "--background-index",
      -- 标记compelie_commands.json文件的目录位置
      -- 关于complie_commands.json如何生成可见我上一篇文章的末尾
      -- https://zhuanlan.zhihu.com/p/84876003
      -- "--compile-commands-dir=build",
      -- 同时开启的任务数量
      "-j=15", -- 告诉clangd用那个clang进行编译，路径参考which clang++的路径
      -- "--query-driver=/usr/bin/clang++",
      -- clang-tidy功能
      "--clang-tidy", -- "--clang-tidy-checks=performance-*,bugprone-*",
      -- "--clang-tidy-checks=*",
      -- 全局补全（会自动补充头文件）
      "--all-scopes-completion", -- 更详细的补全内容
      "--completion-style=detailed", -- 补充头文件的形式
      "--header-insertion=iwyu", -- pch优化的位置
      "--pch-storage=memory", -- "--query-driver=/data/opt/gcc-5.4.0/bin/g++",
      "--function-arg-placeholders",
      -- "-Wuninitialized",
      -- '--query-driver="/usr/local/opt/gcc-arm-none-eabi-8-2019-q3-update/bin/arm-none-eabi-gcc"'
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "hpp", "h" },
    commands = {
      ClangdSwitchSourceHeader = {
        function()
          switch_source_header_splitcmd(0, "edit")
        end,
        description = "Open source/header in current buffer",
      },
      Format = {
        function()
          require("utils.lsp").format()
        end,
        description = "format",
      },
    },
  }

  -- 4. other python json yaml cmake ts bash vimls
  lspconfig.pyright.setup { on_attach = key_on_attach() }

  -- json format :%!python -m json.tool
  lspconfig.jsonls.setup {
    on_attach = key_on_attach(),
    cmd = { "vscode-json-languageserver", "--stdio" },
    filetypes = { "json" },
  }

  lspconfig.yamlls.setup {
    on_attach = key_on_attach(),
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml" },
  }
  -- lspinstall cmake
  lspconfig.cmake.setup {
    -- YOUR_PATH
    cmd = { "/data/yc/.local/share/nvim/lspinstall/cmake/venv/bin/cmake-language-server" },
    on_attach = key_on_attach(),
    filetypes = { "cmake" },
  }

  lspconfig.tsserver.setup { on_attach = key_on_attach() }
  -- lspconfig.denols.setup {
  --   on_attach = key_on_attach(),
  -- }

  -- https://github.com/bash-lsp/bash-language-server
  lspconfig.bashls.setup { on_attach = key_on_attach() }

  lspconfig.vimls.setup { on_attach = key_on_attach() }
end

M.rust_config = function()
  -- lspconfig.rust_analyzer.setup({
  --     on_attach = key_on_attach(),
  --     settings = {
  --         ["rust-analyzer"] = {
  --             assist = {importGranularity = "module", importPrefix = "by_self"},
  --             cargo = {loadOutDirsFromCheck = true},
  --             procMacro = {enable = true}
  --         }
  --     }
  -- })
  local rt = require "rust-tools"
  rt.setup { server = { on_attach = key_on_attach { rust = true, rt = rt } } }
end

return M
