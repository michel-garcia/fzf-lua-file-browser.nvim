local FileBrowser = require("fzf-lua-file-browser.browser")

local M = {}

M.setup = function (config)
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        return vim.notify("fzf-lua was not found", "error")
    end
    fzf.file_browser = function (opts)
        opts = vim.tbl_extend("force", config or {}, opts or {})
        return FileBrowser(opts)
    end
end

return M
