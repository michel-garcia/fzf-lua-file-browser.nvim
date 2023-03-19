local win = require("fzf-lua.win")

local browse = function (opts)
    local FileBrowser = require("fzf-lua-file-browser.browser")
    return FileBrowser(opts)
end

local M = {}

M.abort = function ()
    win.win_leave()
end

M.default = function (selected, opts)
    local path = vim.fn.resolve(table.concat({ opts.cwd, selected[1] }, "/"))
    if vim.fn.isdirectory(path) ~= 0 then
        opts.cwd = path
        return browse(opts)
    end
    M.abort()
    vim.cmd.edit(path)
end

M.create = function (_, opts)
    local ok, res = pcall(vim.fn.input, "Enter filename: ")
    if not ok or not res then
        return browse(opts)
    end
    local path = vim.fn.resolve(table.concat({ opts.cwd, res }, "/"))
    if string.sub(res, -1) == "/" then
        vim.loop.fs_mkdir(path, 448)
    else
        local handle = vim.loop.fs_open(path, "w", 420)
        if handle then
            vim.loop.fs_close(handle)
        else
            vim.notify(string.format("Could not create %s", res), "error")
        end
    end
    browse(opts)
end

M.move = function (selected, opts)
    if vim.fn.resolve(selected[1]) == ".." then
        return browse(opts)
    end
    local path = vim.fn.resolve(table.concat({ opts.cwd, selected[1] }, "/"))
    local prompt = string.format("Move %s to: ", path)
    local ok, res = pcall(vim.fn.input, prompt, path)
    if not ok or not res or res == path then
        return browse(opts)
    end
    if not vim.loop.fs_rename(path, res) then
        vim.notify(string.format("Failed to move %s", path), "error")
    end
    browse(opts)
end

M.delete = function (selected, opts)
    if vim.fn.resolve(selected[1]) == ".." then
        return browse(opts)
    end
    local path = vim.fn.resolve(table.concat({ opts.cwd, selected[1] }, "/"))
    local prompt = string.format("Delete %s? [y/n] ", path)
    local ok, res = pcall(vim.fn.input, prompt)
    if not ok or res ~= "y" then
        return browse(opts)
    end
    if vim.fn.isdirectory(path) == 0 then
        if not vim.loop.fs_unlink(path) then
            vim.browse(string.format("Failed to delete %s", path), "error")
        end
    else
        if not vim.loop.fs_rmdir(path) then
            vim.notify(string.format("Failed to delete %s", path), "error")
        end
    end
    browse(opts)
end

M.toggle_hidden = function (_, opts)
    opts.hidden = not opts.hidden
    browse(opts)
end

M.go_to_parent = function (_, opts)
    opts.cwd = vim.fn.fnamemodify(opts.cwd, ":h:p")
    browse(opts)
end

M.go_to_home = function (_, opts)
    opts.cwd = vim.loop.os_homedir()
    browse(opts)
end

M.go_to_cwd = function (_, opts)
    opts.cwd = vim.loop.cwd()
    browse(opts)
end

return M
