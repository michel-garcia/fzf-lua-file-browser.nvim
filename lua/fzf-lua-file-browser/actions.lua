local Path = require("fzf-lua-file-browser.path")

local M = {}

local browse = function (opts)
    local ok, fzf = pcall(require, "fzf-lua")
    if ok then
        fzf.file_browser(opts)
    end
end

M.edit_or_browse = function (selected, opts)
    if next(selected) then
        local path = Path(opts.cwd, selected[1])
        if path:is_file() then
            local filename = path:str()
            vim.cmd.edit(filename)
            return
        end
        opts.cwd = path:str()
    end
    browse(opts)
end

M.go_to_parent = function (_, opts)
    local path = Path(opts.cwd)
    local parent = path:parent()
    opts.cwd = parent:str()
    local basename = path:basename()
    opts.selection = basename
    browse(opts)
end

M.go_to_cwd = function (_, opts)
    opts.cwd = Path.cwd():str()
    browse(opts)
end

M.toggle_hidden = function (_, opts)
    opts.hidden = not opts.hidden
    browse(opts)
end

M.go_to_home = function (_, opts)
    opts.cwd = Path.home():str()
    browse(opts)
end

M.create = function (_, opts)
    local ok, input = pcall(vim.fn.input, "Enter filename: ")
    if ok and input ~= "" then
        local path = Path(opts.cwd, input)
        if path:exists() then
            local message = string.format("%s already exists", path)
            vim.notify(message, "error")
        else
            ok = path:create()
            if ok then
                opts.selection = path:basename()
            else
                local message = string.format(
                    "Failed to create %s", input
                )
                vim.notify(message, "error")
            end
        end
    end
    browse(opts)
end

M.rename = function (selected, opts)
    if next(selected) then
        local path = Path(opts.cwd, selected[1])
        local prompt = string.format("Move %s to: ", path)
        local ok, input = pcall(vim.fn.input, prompt, path:str())
        if ok and input ~= "" and input ~= path:str() then
            if Path(input):exists() then
                local message = string.format(
                    "%s already exists", input
                )
                vim.notify(message, "error")
            else
                ok = path:rename(input)
                if ok then
                    opts.selection = Path(input):basename()
                else
                    local message = string.format(
                        "Failed to move %s", path
                    )
                    vim.notify(message, "error")
                end
            end
        end
    end
    browse(opts)
end

M.delete = function (selected, opts)
    if next(selected) then
        local path = Path(opts.cwd, selected[1])
        local prompt = string.format("Delete %s? [y/n] ", path)
        local ok, input = pcall(vim.fn.input, prompt)
        if ok and input == "y" then
            ok = path:delete()
            if not ok then
                local message = string.format(
                    "Failed to delete %s", path
                )
                vim.notify(message, "error")
            end
        end
    end
    browse(opts)
end

return M
