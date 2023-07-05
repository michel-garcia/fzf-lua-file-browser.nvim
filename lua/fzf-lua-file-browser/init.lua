local Path = require("fzf-lua-file-browser.path")

local M = {}

local loaded = false

M.actions = {
    edit_or_browse = function (selected, opts)
        if next(selected) then
            local path = Path(opts.cwd, selected[1])
            if path:is_file() then
                local filename = tostring(path)
                vim.cmd.edit(filename)
                return
            end
            opts.cwd = tostring(path)
        end
        M.browse(opts)
    end,
    go_to_parent = function (_, opts)
        local path = Path(opts.cwd):parent()
        opts.cwd = tostring(path)
        M.browse(opts)
    end,
    go_to_cwd = function (_, opts)
        opts.cwd = tostring(Path.cwd())
        M.browse(opts)
    end,
    toggle_hidden = function (_, opts)
        opts.hidden = not opts.hidden
        M.browse(opts)
    end,
    go_to_home = function (_, opts)
        opts.cwd = tostring(Path.home())
        M.browse(opts)
    end,
    create = function (_, opts)
        local ok, input = pcall(vim.fn.input, "Enter filename: ")
        if ok and input ~= "" then
            local path = Path(opts.cwd, input)
            if path:exists() then
                local message = string.format("%s already exists", path)
                vim.notify(message, "error")
            else
                ok = path:create()
                if not ok then
                    local message = string.format(
                        "Failed to create %s", input
                    )
                    vim.notify(message, "error")
                end
            end
        end
        M.browse(opts)
    end,
    rename = function (selected, opts)
        if next(selected) then
            local path = Path(opts.cwd, selected[1])
            local prompt = string.format("Move %s to: ", path)
            local ok, input = pcall(vim.fn.input, prompt, path)
            if ok and input ~= "" and input ~= path then
                if Path(input):exists() then
                    local message = string.format(
                        "%s already exists", input
                    )
                    vim.notify(message, "error")
                else
                    ok = path:rename(input)
                    if not ok then
                        local message = string.format(
                            "Failed to move %s", path
                        )
                        vim.notify(message, "error")
                    end
                end
            end
        end
        M.browse(opts)
    end,
    delete = function (selected, opts)
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
        M.browse(opts)
    end
}

M.opts = {
    actions = {
        ["default"] = M.actions.edit_or_browse,
        ["ctrl-g"] = M.actions.go_to_parent,
        ["ctrl-w"] = M.actions.go_to_cwd,
        ["ctrl-h"] = M.actions.toggle_hidden,
        ["ctrl-e"] = M.actions.go_to_home,
        ["ctrl-a"] = M.actions.create,
        ["ctrl-r"] = M.actions.rename,
        ["ctrl-x"] = M.actions.delete
    },
    hidden = false,
    no_header = true,
    prompt = "File Browser> "
}

M.setup = function (opts)
    if loaded then
        return
    end
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        return
    end
    M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    if fzf.file_browser then
        vim.notify("Existing FzfLua file browser extension detected", "warn")
        return
    end
    fzf.file_browser = M.browse
    loaded = true
end

M.browse = function (opts)
    local fzf = require("fzf-lua")
    opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    opts.cmd = "ls --almost-all --color=always --group-directories-first"
    if not opts.hidden then
        opts.cmd = "ls --color=always --group-directories-first"
    end
    opts.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.loop.cwd()
    fzf.files(opts)
end

return M
