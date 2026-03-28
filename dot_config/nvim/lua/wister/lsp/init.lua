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

-- enable LSP
local lsp_names = {
    'lua_ls',
    'gopls',
}

vim.lsp.enable(lsp_names)
