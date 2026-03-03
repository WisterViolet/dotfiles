-- set line number
vim.opt.number = true
vim.opt.cursorline = true

-- set tab width 4 spaces
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4


vim.opt.scrolloff = 3

-- connect line right and next line left 
vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'

vim.api.nvim_create_user_command(
    'Initlua',
    function()
        vim.cmd.edit(vim.fn.stdpath('config') .. '/init.lua')
    end,
    {}
)

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('init.lua', {})

-- wrapper function to use intertnal augroup
local function create_autocmd(event, opts)
    vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', {
        group = augroup,
    }, opts))
end

-- auto create directry if path not found
-- https://vim-jp.org/vim-users-jp/2011/02/20/Hack-202.html
create_autocmd('BufWritePre', {
    pattern = '*',
    callback = function(event)
        local dir = vim.fs.dirname(event.file)
        local force = vim.v.cmdbang == 1
        if vim.fn.isdirectory(dir) == 0
                and (force or vim.fn.confirm('"' .. dir .. '" does not exist. Create?', "&Yes\n&No") == 1) then
            vim.fn.mkdir(vim.fn.iconv(dir, vim.opt.encoding:get(), vim.opt.termencoding:get()), 'p')
        end
    end,
    desc = 'Auto mkdir to save file'
})

--keymap
vim.keymap.set({'i','x'},'jj', '<esc>', {desc = 'jj escape'})
vim.keymap.set({'n'},'p', 'p`]', {desc = 'Paste and move to the end'})
vim.keymap.set({'n'},'P', 'P`]', {desc = 'Paste and move to the top'})
vim.keymap.set({'x'},'p', 'P', {desc = 'Paste without change register'})
vim.keymap.set({'x'},'P', 'p', {desc = 'Paste with change register'})

-- abbreviation only for ex-command
local function abbrev_excmd(lhs, rhs, opts)
  vim.keymap.set('ca', lhs, function()
    return vim.fn.getcmdtype() == ':' and rhs or lhs
  end, vim.tbl_extend('force', { expr = true }, opts))
end

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.nvim`" | redraw')
    local clone_cmd = {
        'git', 'clone', '--filter=blob:none',
        'https://github.com/nvim-mini/mini.nvim', mini_path
    }
    vim.fn.system(clone_cmd)
    vim.cmd('packadd mini.nvim | helptags ALL')
    vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package }})

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
    require('mini.icons').setup()
end)

now(function()
    require('mini.statusline').setup()
    vim.opt.laststatus = 3
    vim.opt.cmdheight = 0
    create_autocmd({ 'RecordingEnter', 'CmdlineEnter' }, {
    pattern = '*',
    callback = function()
        vim.opt.cmdheight = 1
    end,
    })
    create_autocmd('RecordingLeave', {
    pattern = '*',
    callback = function()
        vim.opt.cmdheight = 0
    end,
    })
    create_autocmd('CmdlineLeave', {
    pattern = '*',
    callback = function()
        if vim.fn.reg_recording() == '' then
        vim.opt.cmdheight = 0
        end
    end,
    })
end)

now(function()
    require('mini.misc').setup()
    MiniMisc.setup_restore_cursor()
end)

now(function()
    require('mini.notify').setup()

    vim.notify = require('mini.notify').make_notify({})
    vim.api.nvim_create_user_command('NotifyHistory', function()
        MiniNotify.show_history()
    end, { desc = 'Show notify history' })
end)
