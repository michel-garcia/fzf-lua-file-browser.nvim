local M = {}
M.__index = M

M.__tostring = function (self)
    return self.path
end

M.separator = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

M.home = function ()
    return M.new(vim.loop.os_homedir())
end

M.cwd = function ()
    return M.new(vim.loop.cwd())
end

M.new = function (...)
    local self = setmetatable({}, M)
    self.path = table.concat({ ... }, M.separator)
    return self
end

M.exists = function (self)
    local stat = vim.loop.fs_stat(self.path)
    return not vim.tbl_isempty(stat or {})
end

M.is_dir = function (self)
    if not self:exists() then
        return vim.endswith(self.path, M.separator)
    end
    local stat = vim.loop.fs_stat(self.path)
    return stat.type == "directory"
end

M.is_file = function (self)
    return not self:is_dir()
end

M.parent = function (self)
    return M.new(vim.fn.fnamemodify(self.path, ":h:p"))
end

M.create = function (self)
    if self:exists() then
        return false
    end
    if self:is_dir() then
        return vim.loop.fs_mkdir(self.path, 448)
    end
    local handle = vim.loop.fs_open(self.path, "w", 420)
    if handle then
        vim.loop.fs_close(handle)
        return true
    end
    return false
end

M.rename = function (self, path)
    if not self:exists() then
        return false
    end
    return vim.loop.fs_rename(self.path, path)
end

M.delete = function (self)
    if not self:exists() then
        return false
    end
    if self:is_dir() then
        return vim.loop.fs_rmdir(self.path)
    else
        return vim.loop.fs_unlink(self.path)
    end
end

return setmetatable(M, {
    __call = function (self, ...)
        return self.new(...)
    end
})
