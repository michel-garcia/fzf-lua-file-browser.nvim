local fzf_actions = require("fzf-lua.actions")
local fzf_path = require("fzf-lua.path")

local M = {}

M.open = function(selected, opts)
    if not next(selected) then
        return
    end
    local key = selected[1]
    local browser = require("fzf-lua-file-browser")
    local file = browser.state.files[key] or nil
    if not file then
        return
    end
    if not file.is_dir then
        fzf_actions.file_edit({ file.path }, opts)
        return
    end
    browser.state.cwd = file.path
    browser.browse(vim.tbl_extend("force", opts, { cwd = browser.state.cwd }))
end

M.parent = function(_, opts)
    local browser = require("fzf-lua-file-browser")
    browser.state.active = vim.fn.fnamemodify(vim.fs.normalize(browser.state.cwd), ":t")
    browser.state.cwd = fzf_path.parent(browser.state.cwd)
    browser.browse(vim.tbl_extend("force", opts, { cwd = browser.state.cwd }))
end

M.cwd = function(_, opts)
    local browser = require("fzf-lua-file-browser")
    browser.state.cwd = vim.loop.cwd()
    browser.browse(vim.tbl_extend("force", opts, { cwd = browser.state.cwd }))
end

M.home = function(_, opts)
    local browser = require("fzf-lua-file-browser")
    browser.state.cwd = vim.loop.os_homedir()
    browser.browse(vim.tbl_extend("force", opts, { cwd = browser.state.cwd }))
end

M.toggle_hidden = function(_, opts)
    local browser = require("fzf-lua-file-browser")
    browser.state.hidden = not browser.state.hidden
    browser.browse(opts)
end

M.create = function(_, opts)
    vim.ui.input({
        prompt = "New name: ",
    }, function(name)
        local browser = require("fzf-lua-file-browser")
        if name then
            local cwd = opts.cwd or browser.state.cwd
            local path = fzf_path.join({ cwd, name })
            local stat = vim.loop.fs_stat(path) or {}
            if vim.tbl_isempty(stat) then
                if name:sub(-1) == "/" then
                    vim.loop.fs_mkdir(path, 493)
                else
                    local handle = vim.loop.fs_open(path, "w", 420)
                    if handle then
                        vim.loop.fs_close(handle)
                    end
                end
            else
                vim.notify("File already exists.", vim.log.levels.ERROR)
            end
            browser.state.active = name
        end
        browser.browse(opts)
    end)
end

M.rename = function(selected, opts)
    if not next(selected) then
        return
    end
    local browser = require("fzf-lua-file-browser")
    local key = selected[1]
    local file = browser.state.files[key] or nil
    if not file then
        return
    end
    vim.ui.input({
        prompt = "New name: ",
        default = file.name,
    }, function(name)
        if name then
            local cwd = opts.cwd or browser.state.cwd
            local path = fzf_path.join({ cwd, name })
            local stat = vim.loop.fs_stat(path) or {}
            if vim.tbl_isempty(stat) then
                vim.loop.fs_rename(file.path, path)
            else
                vim.notify("File already exists.", vim.log.levels.ERROR)
            end
            browser.state.active = name
        end
        browser.browse(opts)
    end)
end

M.delete = function(selected, opts)
    if not next(selected) then
        return
    end
    local key = selected[1]
    local browser = require("fzf-lua-file-browser")
    local file = browser.state.files[key]
    vim.ui.input({
        prompt = string.format("Delete %s? [y/n]", file.name),
    }, function(input)
        if input == "y" then
            if file.is_dir then
                vim.loop.fs_rmdir(file.path)
            else
                vim.loop.fs_unlink(file.path)
            end
            browser.browse(opts)
        end
    end)
end

return M
