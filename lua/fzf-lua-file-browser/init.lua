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
            local ok, input = pcall(vim.fn.input, prompt, tostring(path))
            if ok and input ~= "" and input ~= tostring(path) then
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
    colored = true,
    group_directories_first = true,
    hidden = false,
    natural_sort = true,
    no_header = true,
    prompt = "File Browser> ",
    reverse = false,
    sort = "name"
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
    local args = {}
    if opts.colored then
        table.insert(args, "--color=always")
    end
    if opts.group_directories_first then
        table.insert(args, "--group-directories-first")
    end
    if opts.hidden then
        table.insert(args, "--almost-all")
    end
    if opts.natural_sort then
        table.insert(args, "-v")
    end
    if opts.reverse then
        table.insert(args, "--reverse")
    end
    if opts.sort ~= "name" then
        local SORT = {
            "none",
            "size",
            "time",
            "version",
            "extension",
            "width"
        }
        if vim.tbl_contains(SORT, opts.sort) then
            table.insert(args, string.format("--sort=%s", opts.sort))
        end
    end
    opts.cmd = string.format("ls %s", table.concat(args, " "))
    opts.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.loop.cwd()
    fzf.files(opts)
end

return M
