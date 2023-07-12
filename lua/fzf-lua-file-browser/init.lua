local Path = require("fzf-lua-file-browser.path")
local actions = require("fzf-lua-file-browser.actions")
local utils = require("fzf-lua-file-browser.utils")

local M = {}

local loaded = false

M.opts = {
    actions = {
        ["default"] = actions.edit_or_browse,
        ["ctrl-g"] = actions.go_to_parent,
        ["ctrl-w"] = actions.go_to_cwd,
        ["ctrl-h"] = actions.toggle_hidden,
        ["ctrl-e"] = actions.go_to_home,
        ["ctrl-a"] = actions.create,
        ["ctrl-r"] = actions.rename,
        ["ctrl-x"] = actions.delete
    },
    cwd = nil,
    fzf_opts = {},
    group_directories_first = true,
    hidden = false,
    natural_sort = true,
    prompt = "File Browser> ",
    reverse = false,
    show_cwd_header = true,
    sort = "name"
}

M.setup = function (opts)
    if loaded then
        return
    end
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        return
    end
    M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    if fzf.file_browser then
        vim.notify("Existing FzfLua file browser extension detected", "warn")
        return
    end
    fzf.file_browser = M.browse
    loaded = true
end

M.browse = function (opts)
    opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    if not opts.cwd then
        opts.selection = vim.fn.expand("%:t:h")
    end
    opts.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.loop.cwd()
    if opts.show_cwd_header then
        local header = vim.fn.fnamemodify(opts.cwd, ":~")
        opts.fzf_opts["--header"] = header
    end
    opts.files = Path(opts.cwd):files()
    if not opts.hidden then
        opts.files = vim.tbl_filter(function (file)
            return not file:is_hidden()
        end, opts.files)
    end
    utils.sort(opts.files, opts)
    if opts.reverse then
        opts.files = utils.reverse(opts.files)
    end
    if opts.selection then
        local index = vim.fn.indexof(opts.files, function (_, file)
            return Path(file.path):basename() == opts.selection
        end)
        if index > 0 then
            local steps = {}
            for _ = 1, index do
                table.insert(steps, "down")
            end
            opts.fzf_args = string.format(
                "--sync --bind start:%s", table.concat(steps, "+")
            )
        end
    end
    local core = require("fzf-lua.core")
    core.fzf_exec(function (callback)
        for _, file in ipairs(opts.files) do
            callback(file:basename())
        end
        callback()
    end, opts)
end

return M
