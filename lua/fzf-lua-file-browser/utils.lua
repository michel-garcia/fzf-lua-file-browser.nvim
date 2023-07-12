local Path = require("fzf-lua-file-browser.path")

local M = {}

M.sort = function (files, opts)
    return table.sort(files, function (a, b)
        if opts.group_directories_first then
            if a:is_dir() and not b:is_dir() then
                return true
            elseif not a:is_dir() and b:is_dir() then
                return false
            end
        end
        if opts.sort == "name" then
            if a:is_hidden() and not b:is_hidden() then
                return true
            elseif not a:is_hidden() and b:is_hidden() then
                return false
            end
            if not opts.natural_sort then
                return a:str() < b:str()
            end
            return a:str():lower() < b:str():lower()
        end
        if opts.sort == "width" then
            return a:str():len() < b:str():len()
        end
        return true
    end)
end

M.reverse = function (files)
    local reversed = {}
    local count = vim.tbl_count(files)
    for i = count, 1, -1 do
        table.insert(reversed, files[i])
    end
    return reversed
end

return M
