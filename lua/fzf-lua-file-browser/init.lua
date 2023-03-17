local M = {}
M.__index = M

M.opts = {
    hidden = true
}

M.setup = function (opts)
    M.opts = vim.tbl_extend("force", M.opts, opts or {})
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        return vim.notify("fzf-lua was not found", "error")
    end
    fzf.file_browser = function (...)
        return M.new(...)
    end
end

M.new = function (opts)
    local self = setmetatable({}, M)
    self.opts.cwd = vim.fn.expand("%:p:h") or vim.loop.cwd()
    self.opts = vim.tbl_extend("force", self.opts, opts or {})
    self:browse()
    return self
end

M.browse = function (self)
    local fzf = require("fzf-lua")
    fzf.fzf_exec(function (callback)
        local files = vim.fn.readdir(self.opts.cwd)
        if self.opts.cwd ~= "/" then
            table.insert(files, 1, "..")
        end
        self.entries = {}
        for _, name in ipairs(files) do
            local path = vim.fn.resolve(table.concat({
                self.opts.cwd,
                name
            }, "/"))
            local key = name
            if vim.fn.isdirectory(path) ~= 0 then
                key = string.format("%s/", key)
            end
            local entry = self:add_entry(key, name, path)
            entry.hidden = string.sub(name, 1, 1) == "." and name ~= ".."
            if self.opts.hidden or not entry.hidden then
                callback(key)
            end
        end
        callback()
    end, {
        actions = {
            ["default"] = function (selected)
                local key = selected[1]
                local entry = self:get_entry(key)
                self:default(entry.path)
            end,
            ["esc"] = function ()
                self:close()
            end,
            ["ctrl-c"] = function ()
                self:close()
            end,
            ["ctrl-h"] = function ()
                self.opts.hidden = not self.opts.hidden
                self:browse()
            end,
            ["ctrl-g"] = function ()
                self.opts.cwd = vim.fn.fnamemodify(self.opts.cwd, ":h:p")
                self:browse()
            end,
            ["ctrl-e"] = function ()
                self.opts.cwd = vim.loop.os_homedir()
                self:browse()
            end,
            ["ctrl-w"] = function ()
                self.opts.cwd = vim.loop.cwd()
                self:browse()
            end,
            ["ctrl-a"] = function ()
                local prompt = "Enter filename: "
                local ok, res = pcall(vim.fn.input, prompt)
                if ok and res then
                    local created = self:create(res)
                    if not created then
                        vim.notify(string.format(
                            "Could not create %s",
                            res
                        ), "error")
                    end
                end
                self:browse()
            end,
            ["ctrl-r"] = function (selected)
                local key = selected[1]
                local entry = self:get_entry(key)
                if entry.name == ".." then
                    return self:browse()
                end
                local prompt = string.format("Move %s to: ", entry.path)
                local ok, res = pcall(vim.fn.input, prompt, entry.path)
                if ok and res then
                    if res ~= entry.path then
                        local moved = self:move(entry.path, res)
                        if not moved then
                            vim.notify(string.format(
                                "Failed to move %s",
                                entry.path
                            ), "error")
                        end
                    end
                end
                self:browse()
            end,
            ["ctrl-x"] = function (selected)
                local key = selected[1]
                local entry = self:get_entry(key)
                if entry.name == ".." then
                    return self:browse()
                end
                local prompt = string.format("Delete %s? [y/n] ", entry.path)
                local ok, res = pcall(vim.fn.input, prompt)
                if ok and res == "y" then
                    local deleted = self:delete(entry.path)
                    if not deleted then
                        vim.notify(string.format(
                            "Failed to delete %s",
                            entry.path
                        ), "error")
                    end
                end
                self:browse()
            end
        },
        autoclose = false
    })
end

M.add_entry = function (self, key, name, path)
    local entry = {
        name = name,
        path = path
    }
    self.entries[key] = entry
    return entry
end

M.get_entry = function (self, key)
    return self.entries[key]
end

M.default = function (self, path)
    if vim.fn.isdirectory(path) ~= 0 then
        self.opts.cwd = path
        return self:browse()
    end
    self:close()
    vim.cmd.edit(path)
end

M.close = function (_)
    local win = require("fzf-lua.win")
    win.win_leave()
end

M.create = function (self, filename)
    local path = vim.fn.resolve(table.concat({
        self.opts.cwd,
        filename
    }, "/"))
    if string.sub(filename, -1) == "/" then
        vim.loop.fs_mkdir(path, 448)
    else
        local handle = vim.loop.fs_open(path, "w", 420)
        if not handle then
            return false
        end
        vim.loop.fs_close(handle)
    end
    return true
end

M.move = function (_, path, dest)
    return vim.loop.fs_rename(path, dest)
end

M.delete = function (_, path)
    if vim.fn.isdirectory(path) == 0 then
        return vim.loop.fs_unlink(path)
    else
        return vim.loop.fs_rmdir(path)
    end
end

return M
