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
vim.keymap.set({ 'i', 'x' }, 'jj', '<esc>', { desc = 'jj escape' })
vim.keymap.set({ 'n' }, 'p', 'p`]', { desc = 'Paste and move to the end' })
vim.keymap.set({ 'n' }, 'P', 'P`]', { desc = 'Paste and move to the top' })
vim.keymap.set({ 'x' }, 'p', 'P', { desc = 'Paste without change register' })
vim.keymap.set({ 'x' }, 'P', 'p', { desc = 'Paste with change register' })

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
require('mini.deps').setup({ path = { package = path_package } })

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
    vim.api.nvim_create_user_command('Zoom', function() MiniMisc.zoom(0, {}) end, { desc = 'Zoom current buffer' })
end)

now(function()
    require('mini.notify').setup()

    vim.notify = require('mini.notify').make_notify({})
    vim.api.nvim_create_user_command('NotifyHistory', function()
        MiniNotify.show_history()
    end, { desc = 'Show notify history' })
end)

later(function()
    local hipatterns = require('mini.hipatterns')
    local hi_words = require('mini.extra').gen_highlighter.words
    hipatterns.setup({
        highlighters = {
            -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
            fixme = hi_words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
            hack = hi_words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
            todo = hi_words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
            note = hi_words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
            -- Highlight hex color strings (`#rrggbb`) using that color
            hex_color = hipatterns.gen_highlighter.hex_color(),
        },
    })
end)

later(function()
    require('mini.cursorword').setup()
end)

later(function()
    require('mini.indentscope').setup()
end)

later(function()
    require('mini.trailspace').setup()
    vim.api.nvim_create_user_command(
        'Trim',
        function()
            MiniTrailspace.trim()
            MiniTrailspace.trim_last_lines()
        end,
        { desc = "Trim trailing space and last blank lines" }
    )
end)

now(function()
    require('mini.starter').setup()
end)

later(function()
    require('mini.pairs').setup()
end)

later(function()
    require('mini.surround').setup()
end)

later(function()
    local gen_ai_spec = require('mini.extra').gen_ai_spec
    require('mini.ai').setup({
        custom_textobjects = {
            B = gen_ai_spec.buffer(),
            D = gen_ai_spec.diagnostic(),
            I = gen_ai_spec.indent(),
            L = gen_ai_spec.line(),
            N = gen_ai_spec.number(),
            J = { { '()%d%d%d%d%-%d%d%-%d%d()', '()%d%d%d%d%/%d%d%/%d%d()' } }
        },
    })
end)

later(function()
    local function mode_nx(keys)
        return { mode = 'n', keys = keys }, { mode = 'x', keys = keys }
    end
    local clue = require('mini.clue')
    clue.setup({
        triggers = {
            -- Leader triggers
            mode_nx('<leader>'),

            -- Built-in completion
            { mode = 'i', keys = '<c-x>' },

            -- `g` key
            mode_nx('g'),

            -- Marks
            mode_nx("'"),
            mode_nx('`'),

            -- Registers
            mode_nx('"'),
            { mode = 'i', keys = '<c-r>' },
            { mode = 'c', keys = '<c-r>' },

            -- Window commands
            { mode = 'n', keys = '<c-w>' },

            -- bracketed commands
            { mode = 'n', keys = '[' },
            { mode = 'n', keys = ']' },

            -- `z` key
            mode_nx('z'),

            -- surround
            mode_nx('s'),

            -- text object
            { mode = 'x', keys = 'i' },
            { mode = 'x', keys = 'a' },
            { mode = 'o', keys = 'i' },
            { mode = 'o', keys = 'a' },

            -- option toggle (mini.basics)
            { mode = 'n', keys = 'm' },
        },

        clues = {
            -- Enhance this by adding descriptions for <Leader> mapping groups
            clue.gen_clues.builtin_completion(),
            clue.gen_clues.g(),
            clue.gen_clues.marks(),
            clue.gen_clues.registers({ show_contents = true }),
            clue.gen_clues.windows({ submode_resize = true, submode_move = true }),
            clue.gen_clues.z(),
        },
    })
end)

now(function()
    vim.diagnostic.config({
        virtual_text = true
    })
    vim.lsp.config('*', {
        root_markers = { '.git' },
    })
    vim.lsp.config('lua_ls', {
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        on_init = function(client)
            if client.workspace_folders then
                local path = client.workspace_folders[1].name
                if path ~= vim.fn.stdpath('config') and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
                    return
                end
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                runtime = { version = 'LuaJIT' },
                workspace = {
                    checkThirdParty = false,
                    library = vim.list_extend(vim.api.nvim_get_runtime_file('lua', true), {
                        "${3rd}/luv/library",
                        "${3rd}/busted/library",
                    }),
                }
            })
        end,
        settings = {
            Lua = {
                diagnostics = {
                    -- 未使用変数は冒頭に`_`をつけていれば警告なし
                    unusedLocalExclude = { '_*' }
                }
            }
        }
    })
    vim.lsp.enable('lua_ls')
    create_autocmd('LspAttach', {
        callback = function(args)
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

            vim.keymap.set('n', 'grd', function()
                vim.lsp.buf.definition()
            end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

            vim.keymap.set('n', '<space>i', function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
            end, { buffer = args.buf, desc = 'Format buffer' })
        end,
    })
end)

later(function()
    require('mini.fuzzy').setup()
    require('mini.completion').setup({
        lsp_completion = {
            process_items = MiniFuzzy.process_lsp_items,
        },
    })

    -- improve fallback completion
    vim.opt.complete = { '.', 'w', 'k', 'b', 'u', 't', 'i' }
    vim.opt.completeopt:append('fuzzy')
    -- vim.opt.dictionary:append('/path/to/word/dictionary')

    -- define keycodes
    local keys = {
        cn = vim.keycode('<c-n>'),
        cp = vim.keycode('<c-p>'),
        ct = vim.keycode('<c-t>'),
        cd = vim.keycode('<c-d>'),
        cr = vim.keycode('<cr>'),
        cy = vim.keycode('<c-y>'),
    }

    -- select by <tab>/<s-tab>
    vim.keymap.set('i', '<tab>', function()
        -- popup is visible -> next item
        -- popup is NOT visible -> add indent
        return vim.fn.pumvisible() == 1 and keys.cn or keys.ct
    end, { expr = true, desc = 'Select next item if popup is visible' })
    vim.keymap.set('i', '<s-tab>', function()
        -- popup is visible -> previous item
        -- popup is NOT visible -> remove indent
        return vim.fn.pumvisible() == 1 and keys.cp or keys.cd
    end, { expr = true, desc = 'Select previous item if popup is visible' })

    -- complete by <cr>
    vim.keymap.set('i', '<cr>', function()
        if vim.fn.pumvisible() == 0 then
            -- popup is NOT visible -> insert newline
            return require('mini.pairs').cr()
        end
        local item_selected = vim.fn.complete_info()['selected'] ~= -1
        if item_selected then
            -- popup is visible and item is selected -> complete item
            return keys.cy
        end
        -- popup is visible but item is NOT selected -> hide popup
        return keys.cy
    end, { expr = true, desc = 'Complete current item if item is selected' })
    require('mini.snippets').setup({
        mappings = {
            jump_prev = '<c-k>',
        },
    })
end)

later(function()
    require('mini.tabline').setup()
end)

later(function()
    require('mini.bufremove').setup()

    vim.api.nvim_create_user_command(
        'Bufdelete',
        function()
            MiniBufremove.delete()
        end,
        { desc = 'Remove buffer' }
    )
end)

now(function()
    require('mini.files').setup({
        mappings = {
            go_in_plus = '<cr>',
            go_in = 'L',
            go_out = '<BS>',
            go_out_plus = 'H',
            reset = '~',
        }
    })

    vim.api.nvim_create_user_command(
        'Files',
        function()
            MiniFiles.open()
        end,
        { desc = 'Open file exproler' }
    )

    vim.keymap.set('n', '<space>e', function()
        MiniFiles.open()
    end, { desc = 'Open file explorer' })
end)

later(function()
    require('mini.pick').setup()

    vim.ui.select = MiniPick.ui_select

    vim.keymap.set('n', '<space>f', function()
        MiniPick.builtin.files({ tool = 'git' })
    end, { desc = 'mini.pick.files' })
end)
