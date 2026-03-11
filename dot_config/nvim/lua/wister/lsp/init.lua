vim.diagnostic.config({
    virtual_text = true
})

vim.api.nvim_create_user_command(
    'LspHealth',
    'checkhealth vim.lsp',
    { desc = 'LSP health check' }
)

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('wister/lsp/init.lua', {})

vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

        if client:supports_method('textDocument/definition') then
            vim.keymap.set('n', 'grd', function()
                vim.lsp.buf.definition()
            end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })
        end

        if client:supports_method('textDocument/formatting') then
            vim.keymap.set('n', '<space>i', function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
            end, { buffer = args.buf, desc = 'format buffer' })
        end
    end,
})

vim.lsp.config('*', {
    root_markers = { '.git' },
    capabilities = require('mini.completion').get_lsp_capabilities(),
})

-- This file directry
local dirname = vim.fn.stdpath('config') .. '/lua/wister/lsp'

-- Exist lsp settings
local lsp_names = {}

-- Search lsp settings
for file, ftype in vim.fs.dir(dirname) do
    -- lua file(exclude init.lua)
    if ftype == 'file' and vim.endswith(file, '.lua') and file ~= 'init.lua' then
        -- make lsp name by remove extention
        local lsp_name = file:sub(1, -5) -- fname without '.lua'
        -- load file
        local ok, result = pcall(require, 'wister.lsp.' .. lsp_name)
        if ok then
            -- configure lsp
            vim.lsp.config(lsp_name, result)
            table.insert(lsp_names, lsp_name)
        else
            -- disp error
            vim.notify('Error loading LSP:' .. lsp_name .. '\n' .. result, vim.log.levels.WARN)
        end
    end
end

-- enable LSP
vim.lsp.enable(lsp_names)
