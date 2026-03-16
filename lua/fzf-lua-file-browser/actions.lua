local fzf_actions = require("fzf-lua.actions")
local fzf_path = require("fzf-lua.path")

local filesystem = require("fzf-lua-file-browser.filesystem")
local state = require("fzf-lua-file-browser.state")

local M = {}

M.open = {
    fn = function(selected, opts)
        if vim.tbl_isempty(selected) then
            return
        end
        local key = selected[1]
        local file = state.files[key] or nil
        if not file then
            return
        end
        if file.is_dir then
            state.cwd = file.path
            opts.browser.browse(vim.tbl_extend("force", opts, {
                cwd = state.cwd,
            }))
            return
        end
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_close(win, true)
        fzf_actions.file_edit({
            file.path,
        }, opts)
    end,
    reload = true,
}

M.split = {
    fn = function(selected, opts)
        if vim.tbl_isempty(selected) then
            return
        end
        local key = selected[1]
        local file = state.files[key] or nil
        if not file then
            return
        end
        if file.is_dir then
            vim.notify("Selection must be a file")
            return
        end
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_close(win, true)
        fzf_actions.file_split({
            file.path,
        }, opts)
    end,
    reload = true,
}

M.vsplit = {
    fn = function(selected, opts)
        if vim.tbl_isempty(selected) then
            return
        end
        local key = selected[1]
        local file = state.files[key] or nil
        if not file then
            return
        end
        if file.is_dir then
            vim.notify("Selection must be a file")
            return
        end
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_close(win, true)
        fzf_actions.file_vsplit({
            file.path,
        }, opts)
    end,
    reload = true,
}

M.parent = {
    fn = function(_, opts)
        state.active = vim.fn.fnamemodify(vim.fs.normalize(state.cwd), ":t")
        state.cwd = fzf_path.parent(state.cwd)
        opts.browser.browse(vim.tbl_extend("force", opts, {
            cwd = state.cwd,
        }))
    end,
    reload = true,
}

M.cwd = {
    fn = function(_, opts)
        state.cwd = vim.loop.cwd()
        opts.browser.browse(vim.tbl_extend("force", opts, {
            cwd = state.cwd,
        }))
    end,
    reload = true,
}

M.home = {
    fn = function(_, opts)
        state.cwd = vim.loop.os_homedir()
        opts.browser.browse(vim.tbl_extend("force", opts, {
            cwd = state.cwd,
        }))
    end,
    reload = true,
}

M.toggle_hidden = {
    fn = function(_, opts)
        state.hidden = not state.hidden
        opts.browser.browse(opts)
    end,
    reload = true,
}

M.create = {
    fn = function(_, opts)
        local cwd = opts.cwd or state.cwd
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
            state.active = fzf_path.basename(path)
            opts.browser.browse(opts)
        end)
    end,
    reload = true,
}

M.rename = {
    fn = function(selected, opts)
        if vim.tbl_isempty(selected) then
            return
        end
        local key = selected[1]
        local file = state.files[key] or nil
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
            local buf = vim.fn.bufnr(file.path)
            if buf ~= -1 then
                vim.api.nvim_buf_set_name(buf, path)
                vim.api.nvim_buf_call(buf, function()
                    vim.api.nvim_command("silent! w!")
                end)
            end
            state.active = fzf_path.basename(path)
        end)
        opts.browser.browse(opts)
    end,
    reload = true,
}

M.delete = {
    fn = function(selected, opts)
        if vim.tbl_isempty(selected) then
            return
        end
        local key = selected[1]
        local file = state.files[key] or nil
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
            local current = vim.fn.bufnr(file.path)
            if current ~= -1 then
                local wins = vim.fn.win_findbuf(current)
                for _, win in ipairs(wins) do
                    local buf = vim.api.nvim_create_buf(false, false)
                    vim.api.nvim_win_set_buf(win, buf)
                end
                vim.api.nvim_buf_delete(current, {
                    force = true,
                })
            end
            opts.browser.browse(opts)
        end)
    end,
    reload = true,
}

return M
