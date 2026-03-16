local fzf = require("fzf-lua")

local browser = require("fzf-lua-file-browser.browser")
local config = require("fzf-lua-file-browser.config")
local state = require("fzf-lua-file-browser.state")

local hijack_netrw = function()
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            pcall(vim.api.nvim_clear_autocmds, {
                group = "FileExplorer",
            })
        end,
        once = true,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            vim.schedule(function()
                local bufname = vim.api.nvim_buf_get_name(0)
                if vim.fn.isdirectory(bufname) == 0 then
                    return
                end
                if bufname == vim.g.netrw_bufname then
                    return
                end
                vim.g.netrw_bufname = bufname
                vim.api.nvim_set_option_value("bufhidden", "wipe", {
                    buf = 0,
                })
                browser.browse()
            end)
        end,
        group = vim.api.nvim_create_augroup("FzfLuaFileBrowser", {
            clear = true,
        }),
    })
end

local M = {}

M.setup = function(opts)
    config.opts = vim.tbl_extend("force", config.opts, opts or {})
    state.hidden = config.opts.hidden
    if config.opts.hijack_netrw then
        hijack_netrw()
    end
    fzf.register_extension("file_browser", M.browse, config.opts)
end

M.browse = function(opts)
    browser.browse(opts)
end

return M
