local M = {}

local loaded = false

M.sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

M.actions = {
    edit_or_browse = function (selected, opts)
        if next(selected) then
            local path = table.concat({ opts.cwd, selected[1] }, M.sep)
            if vim.fn.isdirectory(path) == 0 then
                vim.cmd.edit(path)
                return
            end
            opts.cwd = path
        end
        M.browse(opts)
    end,
    go_to_parent = function (_, opts)
        opts.cwd = vim.fn.fnamemodify(opts.cwd, ":h:p")
        M.browse(opts)
    end,
    go_to_cwd = function (_, opts)
        opts.cwd = vim.loop.cwd()
        M.browse(opts)
    end,
    toggle_hidden = function (_, opts)
        opts.hidden = not opts.hidden
        M.browse(opts)
    end,
    go_to_home = function (_, opts)
        opts.cwd = vim.loop.os_homedir()
        M.browse(opts)
    end,
    create = function (_, opts)
        local ok, input = pcall(vim.fn.input, "Enter filename: ")
        if ok and input ~= "" then
            local path = table.concat({ opts.cwd, input }, M.sep)
            if string.sub(path, -1) == "/" then
                vim.loop.fs_mkdir(path, 448)
            else
                local handle = vim.loop.fs_open(path, "w", 420)
                if handle then
                    vim.loop.fs_close(handle)
                else
                    local message = string.format(
                        "Failed to create %s", input
                    )
                    vim.notify(message, "error")
                end
            end
        end
        M.browse(opts)
    end,
    rename = function (selected, opts)
        if next(selected) then
            local path = table.concat({ opts.cwd, selected[1] }, M.sep)
            local prompt = string.format("Move %s to: ", path)
            local ok, input = pcall(vim.fn.input, prompt, path)
            if ok and input ~= "" then
                ok = vim.loop.fs_rename(path, input)
                if not ok then
                    local message = string.format(
                        "Failed to move %s", path
                    )
                    vim.notify(message, "error")
                end
            end
        end
        M.browse(opts)
    end,
    delete = function (selected, opts)
        if next(selected) then
            local path = table.concat({ opts.cwd, selected[1] }, M.sep)
            local prompt = string.format("Delete %s? [y/n] ", path)
            local ok, input = pcall(vim.fn.input, prompt)
            if ok and input == "y" then
                if vim.fn.isdirectory(path) == 0 then
                    ok = vim.loop.fs_unlink(path)
                else
                    ok = vim.loop.fs_rmdir(path)
                end
                if not ok then
                    local message = string.format(
                        "Failed to delete %s", path
                    )
                    vim.notify(message, "error")
                end
            end
        end
        M.browse(opts)
    end
}

M.opts = {
    actions = {
        ["default"] = M.actions.edit_or_browse,
        ["ctrl-g"] = M.actions.go_to_parent,
        ["ctrl-w"] = M.actions.go_to_cwd,
        ["ctrl-h"] = M.actions.toggle_hidden,
        ["ctrl-e"] = M.actions.go_to_home,
        ["ctrl-a"] = M.actions.create,
        ["ctrl-r"] = M.actions.rename,
        ["ctrl-x"] = M.actions.delete
    },
    hidden = false,
    no_header = true,
    prompt = "File Browser> "
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
    local fzf = require("fzf-lua")
    opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    opts.cmd = "ls --almost-all --color=always --group-directories-first"
    if not opts.hidden then
        opts.cmd = "ls --color=always --group-directories-first"
    end
    opts.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.loop.cwd()
    fzf.files(opts)
end

return M
