local fzf_actions = require("fzf-lua.actions")
local fzf_path = require("fzf-lua.path")

local filesystem = require("fzf-lua-file-browser.filesystem")

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

M.create = {
    fn = function(_, opts)
        local browser = require("fzf-lua-file-browser")
        local cwd = opts.cwd or browser.state.cwd
        vim.ui.input({
            prompt = "New path: ",
            default = fzf_path.add_trailing(cwd),
        }, function(path)
            if not path then
                return
            end
            local exists = filesystem.exists(path)
            if exists then
                vim.notify("File already exists.", vim.log.levels.ERROR)
                return
            end
            filesystem.create(path)
            browser.state.active = fzf_path.basename(path)
            browser.browse(opts)
        end)
    end,
    reload = true,
}

M.rename = {
    fn = function(selected, opts)
        if not next(selected) then
            return
        end
        local key = selected[1]
        local browser = require("fzf-lua-file-browser")
        local file = browser.state.files[key] or nil
        if not file then
            return
        end
        vim.ui.input({
            prompt = "New path: ",
            default = file.path,
        }, function(path)
            if not path then
                return
            end
            if path == file.path then
                return
            end
            local exists = filesystem.exists(path)
            if exists then
                vim.notify("File already exists.", vim.log.levels.ERROR)
                return
            end
            file:rename(path)
            browser.state.active = fzf_path.basename(path)
        end)
        browser.browse(opts)
    end,
    reload = true,
}

M.delete = {
    fn = function(selected, opts)
        if not next(selected) then
            return
        end
        local key = selected[1]
        local browser = require("fzf-lua-file-browser")
        local file = browser.state.files[key] or nil
        if not file then
            return
        end
        vim.ui.input({
            prompt = string.format("Delete %s? [y/n] ", file.name),
        }, function(input)
            if input ~= "y" then
                return
            end
            file:delete()
            browser.browse(opts)
        end)
    end,
    reload = true,
}

return M
