-- this is a mess, must organize in the future, also this 
-- was originally not commented correctly

-- [General settings]
vim.g.mapleader = " " -- Sets leader key to space
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show line numbers relative to current line
vim.opt.tabstop = 4 -- Tab size
vim.opt.shiftwidth = 4 -- Indent size
vim.opt.expandtab = true -- Tabs are replaced with spaces
vim.opt.clipboard = 'unnamedplus' -- Share the vim clipboard with system
vim.opt.swapfile = false -- I save often, so I don't need this
vim.opt.signcolumn = 'yes' -- Keeps the lsp gutter always visible
vim.opt.title = true -- Sets the terminal title to nvim
vim.opt.timeoutlen = 300 -- tmux optimization
vim.opt.ttimeoutlen = 10 -- tmux optimization
vim.opt.autoread = true -- tmux optimization
vim.opt.termguicolors = false -- Use my terminal's colors
vim.cmd.colorscheme('vim') -- Use my terminal's colors

-- [Overwrite certain background colors]
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })

-- [Lex customization] 
vim.g.netrw_banner = 0 -- Removes the banner
vim.g.netrw_browse_split = 4 -- Opens selected file in original window
vim.g.netrw_winsize = 25 -- Set Lex size to 25% of window
vim.keymap.set('n', '<leader>e', '<cmd>Lex<CR>', { noremap = true, silent = true, desc = 'Toggle Netrw Explorer' }) -- space + e to toggle Lex

-- [LSP Settings]
vim.diagnostic.config({
  virtual_text = true, -- Shows errors inline
  signs = true, -- Shows icons in the left gutter
  underline = true, -- Unerlines warnings and errors
  update_in_insert = false, -- Waits until exiting insert mode

})

-- Lua
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.git' },
  settings = {
    Lua = {
    -- Setting to explicityly ignore vim for init.lua
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

-- Haskell
vim.lsp.config('hls', {
  cmd = { 'haskell-language-server-wrapper', '--lsp' },
  filetypes = { 'haskell', 'lhaskell' },
  root_markers = { 'hie.yaml', 'cabal.project', 'package.yaml', '.git' },
})

-- Markdown
vim.lsp.config('marksman', {
  cmd = { 'marksman', 'server' },
  filetypes = { 'markdown', 'markdown.mdx' },
  root_markers = { '.git', '.marksman.toml' },
})



local servers = { 'lua_ls', 'pylsp', 'clangd', 'rust_analyzer', 'gopls', 'hls', 'marksman' }
for _, server in ipairs(servers) do -- Loop to load all of the LSP servers
  vim.lsp.enable(server)
end

-- [Status bar customization]
-- Gets the git status for the active directory
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, {
  callback = function()
    vim.fn.jobstart({"git", "status", "--porcelain", "-b"}, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if not data or not data[1] or string.sub(data[1], 1, 2) ~= "##" then
          vim.b.git_branch = ""
          return
        end
        local branch = data[1]:match("^## No commits yet on (.*)")
                    or data[1]:match("^## (.-)%.%.%.")
                    or data[1]:match("^## (.*)")
        local is_dirty = false
        for i = 2, #data do
          if data[i] ~= "" then
            is_dirty = true
            break
          end
        end
        local status_marker = is_dirty and " [+]" or ""
        vim.b.git_branch = "[Git: " .. branch .. status_marker .. "]"
      end
    })
  end
})

function _G.GitStatus()
  return vim.b.git_branch or ""
end
-- Gets the LSP status for the current file
function _G.LspStatus()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end
  return "[LSP: " .. table.concat(client_names, ", ") .. "]"
end
-- The actual command that sets the statusline based on the functions
vim.opt.statusline = " %f %m %{v:lua.GitStatus()} %= %{v:lua.LspStatus()}   %l:%c "

-- Markdown file optimization
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.wrap = true         -- Wrap lines at edge of screen
    vim.opt_local.linebreak = true    -- Don't split words in half
    vim.opt_local.spell = true        -- Enable spell checking
    vim.opt_local.spelllang = "en_us" -- Set dictionary language to english us
  end,
})

vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Smart Tab completion logic
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>' -- Keep Tab as a fallback to go down
  else
    -- Check if cursor is after a space or at the start of a line
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
      return '<Tab>' -- Insert a regular tab space
    else
      return '<C-x><C-o>' -- Trigger native LSP omni-completion
    end
  end
end, { expr = true, replace_keycodes = true, desc = "Autocomplete with Tab" })

-- Use 'j' to navigate DOWN the autocomplete menu
vim.keymap.set('i', 'j', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>' -- Next item
  else
    return 'j'     -- Type 'j' normally
  end
end, { expr = true, replace_keycodes = true, desc = "Menu Down (j)" })

-- Use 'k' to navigate UP the autocomplete menu
vim.keymap.set('i', 'k', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-p>' -- Previous item
  else
    return 'k'     -- Type 'k' normally
  end
end, { expr = true, replace_keycodes = true, desc = "Menu Up (k)" })

-- Press Enter to confirm selection without accidentally adding a new line
vim.keymap.set('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-y>' -- Accept selected item
  else
    return '<CR>'
  end
end, { expr = true, replace_keycodes = true, desc = "Confirm Autocomplete" })
