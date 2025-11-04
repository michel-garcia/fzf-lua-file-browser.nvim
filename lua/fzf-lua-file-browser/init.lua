local fzf = require("fzf-lua")
local fzf_utils = require("fzf-lua.utils")

local actions = require("fzf-lua-file-browser.actions")
local filesystem = require("fzf-lua-file-browser.filesystem")
local previewer = require("fzf-lua-file-browser.previewer")

local hijack_netrw = function()
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            pcall(vim.api.nvim_clear_autocmds, {
                group = "FileExplorer",
            })
        end,
        once = true,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            vim.schedule(function()
                local bufname = vim.api.nvim_buf_get_name(0)
                if vim.fn.isdirectory(bufname) == 0 then
                    return
                end
                if bufname == vim.g.netrw_bufname then
                    return
                end
                vim.g.netrw_bufname = bufname
                vim.api.nvim_set_option_value("bufhidden", "wipe", {
                    buf = 0,
                })
                local browser = require("fzf-lua-file-browser")
                browser.browse()
            end)
        end,
        group = vim.api.nvim_create_augroup("FzfLuaFileBrowser", {
            clear = true,
        }),
    })
end

local M = {}

M.opts = {
    actions = {
        ["default"] = actions.open,
        ["ctrl-g"] = actions.parent,
        ["ctrl-w"] = actions.cwd,
        ["ctrl-e"] = actions.home,
        ["ctrl-t"] = actions.toggle_hidden,
        ["ctrl-a"] = actions.create,
        ["ctrl-r"] = actions.rename,
        ["ctrl-d"] = actions.delete,
    },
    color_icons = true,
    cwd_header = false,
    cwd_prompt = true,
    dir_icon = "󰉋",
    dir_icon_hl = "Directory",
    file_icons = true,
    hidden = true,
    hijack_netrw = false,
    prompt = "> ",
}

M.state = {
    cwd = nil,
    files = {},
    hidden = true,
    active = nil,
}

M.make_item = function(file)
    local _, icons = pcall(require, "nvim-web-devicons")
    local name = file.is_dir and string.format("%s/", file.name) or file.name
    local icon, color = nil, nil
    if M.opts.file_icons and icons then
        if file.is_dir then
            icon = M.opts.dir_icon
            if M.opts.dir_icon_hl then
                local highlight = vim.api.nvim_get_hl(0, {
                    name = M.opts.dir_icon_hl,
                    link = false,
                })
                if highlight and highlight.fg then
                    color = string.format("#%06x", highlight.fg)
                end
            end
        else
            icon, color = icons.get_icon_color(file.name)
            if not icon then
                icon, color = icons.get_icon_color("txt")
            end
        end
    end
    local key = table.concat(
        vim.tbl_filter(function(value)
            return value
        end, { icon, name }),
        " "
    )
    if M.opts.color_icons and color then
        icon = fzf_utils.ansi_from_rgb(color, icon)
    end
    local label = table.concat(
        vim.tbl_filter(function(value)
            return value
        end, { icon, name }),
        " "
    )
    local item = {
        key = key,
        label = label,
        file = file,
    }
    return item
end

M.get_items = function(path)
    local files = filesystem.get_files(path)
    if not M.state.hidden then
        files = vim.tbl_filter(function(file)
            return not file.is_hidden
        end, files)
    end
    table.sort(files, function(a, b)
        if a.type == b.type then
            return a.name:lower() < b.name:lower()
        end
        return a.is_dir
    end)
    local items = {}
    for _, file in ipairs(files) do
        local item = M.make_item(file)
        table.insert(items, item)
    end
    return items
end

M.browse = function(opts)
    opts = opts or {}
    M.state.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.loop.cwd()
    if not opts.cwd then
        M.state.active = vim.fn.expand("%:t:h")
    end
    local fzf_args = {
        "--sync",
        "--bind change:first",
    }
    if M.opts.cwd_header then
        local path = vim.fn.pathshorten(M.state.cwd)
        local arg = string.format("--header=%s", path)
        table.insert(fzf_args, arg)
    end
    local prompt = M.opts.prompt
    if M.opts.cwd_prompt then
        local path = vim.fn.pathshorten(M.state.cwd)
        prompt = string.format("%s/", path)
    end
    local items = M.get_items(M.state.cwd)
    M.state.files = {}
    local lines = {}
    for i, item in ipairs(items) do
        table.insert(lines, item.label)
        M.state.files[item.key] = item.file
        if item.file.name == M.state.active then
            local arg = string.format("--bind start:pos\\(%s\\)", i)
            table.insert(fzf_args, arg)
        end
    end
    fzf.fzf_exec(function(callback)
        for _, line in ipairs(lines) do
            callback(line)
        end
        callback()
    end, {
        actions = M.opts.actions,
        cwd = M.state.cwd,
        fzf_args = table.concat(fzf_args, " "),
        previewer = previewer,
        prompt = prompt,
        winopts = {
            title = " File Browser ",
        },
    })
end

M.setup = function(opts)
    M.opts = vim.tbl_extend("force", M.opts, opts or {})
    M.state.hidden = M.opts.hidden
    if M.opts.hijack_netrw then
        hijack_netrw()
    end
    fzf.file_browser = M.browse
end

return M
