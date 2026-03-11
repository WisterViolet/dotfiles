vim.api.nvim_create_user_command(
    'Initlua',
    function()
        vim.cmd.edit(vim.fn.stdpath('config') .. '/init.lua')
    end,
    {}
)
