vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.swapfile = false
vim.opt.signcolumn = 'yes'

vim.opt.title = true
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10
vim.opt.autoread = true

vim.opt.termguicolors = false
vim.cmd.colorscheme('vim')

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
})

-- Lua
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.git' },
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
})

-- Python
vim.lsp.config('pylsp', {
  cmd = { 'pylsp' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', '.git' },
})

-- C / C++
vim.lsp.config('clangd', {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp' },
  root_markers = { 'compile_commands.json', '.git' },
})

-- Rust
vim.lsp.config('rust_analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
})

-- Go
vim.lsp.config('gopls', {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.mod', '.git' },
})

local servers = { 'lua_ls', 'pylsp', 'clangd', 'rust_analyzer', 'gopls' }

for _, server in ipairs(servers) do
  vim.lsp.enable(server)
end

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, {
  callback = function()
    vim.fn.jobstart({"git", "branch", "--show-current"}, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and data[1] and data[1] ~= "" then
          vim.b.git_branch = "[Git: " .. data[1] .. "]"
        else
          vim.b.git_branch = ""
        end
      end
    })
  end
})

function _G.GitStatus()
  return vim.b.git_branch or ""
end

function _G.LspStatus()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end
  return "[LSP: " .. table.concat(client_names, ", ") .. "]"
end

vim.opt.statusline = " %f %m %{v:lua.GitStatus()} %= %{v:lua.LspStatus()}   %l:%c "

