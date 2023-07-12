local M = {}
M.__index = M

M.__tostring = function (self)
    return self:str()
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

M.str = function (self)
    return vim.fn.resolve(self.path)
end

M.basename = function (self)
    return vim.fn.fnamemodify(self:str(), ":t:h")
end

M.exists = function (self)
    local stat = vim.loop.fs_stat(self:str())
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

M.is_hidden = function (self)
    return vim.startswith(self:str(), ".")
end

M.parent = function (self)
    local path = vim.fn.fnamemodify(self:str(), ":h:p")
    return M.new(path)
end

M.files = function (self)
    local files = {}
    if not self:exists() or not self:is_dir() then
        return files
    end
    local handle = vim.loop.fs_scandir(self:str())
    while true do
        local file = vim.loop.fs_scandir_next(handle)
        if not file then
            break
        end
        local path = M.new(self:str(), file)
        table.insert(files, path)
    end
    return files
end

M.create = function (self)
    if self:exists() then
        return false
    end
    if self:is_dir() then
        return vim.loop.fs_mkdir(self:str(), 448)
    end
    local handle = vim.loop.fs_open(self:str(), "w", 420)
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
    return vim.loop.fs_rename(self:str(), path)
end

M.delete = function (self)
    if not self:exists() then
        return false
    end
    if self:is_dir() then
        return vim.loop.fs_rmdir(self:str())
    else
        return vim.loop.fs_unlink(self:str())
    end
end

return setmetatable(M, {
    __call = function (self, ...)
        return self.new(...)
    end
})
