local M = {}
M.settings = {
    gopls = {
        analyses = {
            unusedparams = true,
        },
        staticcheck = true,
        gofumpt = true,
    },
}

return M
