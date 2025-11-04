local fzf_path = require("fzf-lua.path")

local uv = vim.loop or vim.uv

local M = {}

M.get_files = function(path)
    local handle = uv.fs_scandir(path)
    if not handle then
        return {}
    end
    local files = {}
    while true do
        local name, type = uv.fs_scandir_next(handle)
        if not name then
            break
        end
        if type == "link" then
            local stat = uv.fs_stat(name) or {}
            type = stat and stat.type or "file"
        end
        table.insert(files, {
            name = name,
            type = type,
            is_dir = type == "directory",
            is_hidden = name:sub(1, 1) == ".",
            path = fzf_path.join({ path, name }),
            rename = function(self, target)
                M.rename(self.path, target)
            end,
            delete = function(self)
                M.delete(self.path)
            end,
        })
    end
    return files
end

M.exists = function(path)
    local stat = uv.fs_stat(path) or {}
    return not vim.tbl_isempty(stat)
end

M.create = function(path)
    local exists = M.exists(path)
    if exists then
        return false
    end
    local parent = fzf_path.parent(path)
    vim.fn.mkdir(parent, "p")
    if path:sub(-1) == "/" then
        local mode = tonumber("755", 8)
        return uv.fs_mkdir(path, mode)
    end
    local mode = tonumber("644", 8)
    local handle = uv.fs_open(path, "w", mode)
    if not handle then
        return false
    end
    return uv.fs_close(handle)
end

M.rename = function(src, target)
    if src == target then
        return false
    end
    local exists = M.exists(target)
    if exists then
        return false
    end
    local parent = fzf_path.parent(target)
    vim.fn.mkdir(parent, "p")
    return uv.fs_rename(src, target)
end

M.delete = function(path)
    local stat = uv.fs_stat(path) or {}
    if not stat then
        return false
    end
    if stat.type ~= "directory" then
        return uv.fs_unlink(path)
    end
    local files = M.get_files(path)
    for _, file in ipairs(files) do
        M.delete(file.path)
    end
    return uv.fs_rmdir(path)
end

return M
