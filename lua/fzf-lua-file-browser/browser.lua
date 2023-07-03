local fzf = require("fzf-lua")
local actions = require("fzf-lua-file-browser.actions")

local M = {}
M.__index = M

M.opts = {
    actions = {
        ["default"] = actions.default,
        ["esc"] = actions.abort,
        ["ctrl-c"] = actions.abort,
        ["ctrl-h"] = actions.toggle_hidden,
        ["ctrl-g"] = actions.go_to_parent,
        ["ctrl-e"] = actions.go_to_home,
        ["ctrl-w"] = actions.go_to_cwd,
        ["ctrl-a"] = actions.create,
        ["ctrl-r"] = actions.move,
        ["ctrl-x"] = actions.delete
    },
    autoclose = false,
    fzf_opts = {
        ["--info"] = false
    },
    hidden = true,
    winopts = {
        on_create = function ()
            vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", "<Esc>", {
                noremap = true
            })
        end
    }
}

M.new = function (opts)
    opts = vim.tbl_extend("force", M.opts, opts or {})
    if not opts.cwd then
        opts.cwd = vim.fn.expand("%:p:h") or vim.loop.cwd()
    end
    fzf.fzf_exec(function (callback)
        local files = vim.fn.readdir(opts.cwd)
        for _, name in ipairs(files) do
            local path = vim.fn.resolve(table.concat({ opts.cwd, name }, "/"))
            if vim.fn.isdirectory(path) ~= 0 then
                name = string.format("%s/", name)
            end
            local hidden = string.sub(name, 1, 1) == "."
            if opts.hidden or not hidden then
                callback(name)
            end
        end
        callback()
    end, opts)
end

return setmetatable(M, {
    __call = function (_, ...)
        return M.new(...)
    end
})
