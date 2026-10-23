local fzf = require("fzf-lua")
local devicons = require("fzf-lua.devicons")
local path = require("fzf-lua.path")
local utils = require("fzf-lua.utils")

local M = {}

M.defaults = {
    actions = {
        open = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                local item = table.remove(selected)
                local file = path.entry_to_file(item)
                file.path = path.join({ opts.cwd, file.path })
                local stat = vim.uv.fs_stat(file.path)
                if not stat then
                    return
                end
                if stat.type == "directory" then
                    M.browse({
                        clipboard = opts.clipboard,
                        cwd = file.path,
                        focused = opts.focused,
                        hidden = opts.hidden,
                    })
                    return
                end
                local win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_close(win, true)
                vim.schedule(function()
                    fzf.actions.file_edit({
                        file.path,
                    }, opts)
                end)
            end,
            field_index = "{}",
            reload = true,
        },
        split = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                local item = table.remove(selected)
                local file = path.entry_to_file(item)
                file.path = path.join({ opts.cwd, file.path })
                local stat = vim.uv.fs_stat(file.path)
                if not stat or stat.type == "directory" then
                    return
                end
                local win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_close(win, true)
                vim.schedule(function()
                    fzf.actions.file_split({
                        file.path,
                    }, opts)
                end)
            end,
            field_index = "{}",
            reload = true,
        },
        split_vertical = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                local item = table.remove(selected)
                local file = path.entry_to_file(item)
                file.path = path.join({ opts.cwd, file.path })
                local stat = vim.uv.fs_stat(file.path)
                if not stat or stat.type == "directory" then
                    return
                end
                local win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_close(win, true)
                vim.schedule(function()
                    fzf.actions.file_vsplit({
                        file.path,
                    }, opts)
                end)
            end,
            field_index = "{}",
            reload = true,
        },
        go_to_parent = {
            fn = function(_, opts)
                M.browse({
                    clipboard = opts.clipboard,
                    cwd = path.parent(opts.cwd),
                    focused = opts.focused,
                    hidden = opts.hidden,
                })
            end,
            reload = true,
        },
        go_to_cwd = {
            fn = function(_, opts)
                M.browse({
                    clipboard = opts.clipboard,
                    cwd = vim.uv.cwd(),
                    focused = opts.focused,
                    hidden = opts.hidden,
                })
            end,
            reload = true,
        },
        toggle_hidden = {
            fn = function(_, opts)
                M.browse({
                    clipboard = opts.clipboard,
                    cwd = opts.cwd,
                    focused = opts.focused,
                    hidden = not opts.hidden,
                })
            end,
            reload = true,
        },
        create = {
            fn = function(_, opts)
                vim.ui.input({
                    prompt = "New path: ",
                    default = path.add_trailing(opts.cwd),
                }, function(target)
                    if not target then
                        return
                    end
                    local stat = vim.uv.fs_stat(target)
                    if stat then
                        return
                    end
                    local parent = vim.fs.dirname(vim.fs.normalize(target))
                    vim.fn.mkdir(parent, "p")
                    if string.sub(target, -1) == "/" then
                        local mode = tonumber("755", 8)
                        vim.uv.fs_mkdir(target, mode)
                    else
                        local mode = tonumber("644", 8)
                        local handle = vim.uv.fs_open(target, "w", mode)
                        vim.uv.fs_close(handle)
                    end
                    opts.focused[opts.cwd] = vim.fn.fnamemodify(vim.fs.normalize(target), ":t")
                    M.browse({
                        clipboard = opts.clipboard,
                        cwd = opts.cwd,
                        focused = opts.focused,
                        hidden = opts.hidden,
                    })
                end)
            end,
            reload = true,
        },
        rename = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                local item = table.remove(selected)
                local file = path.entry_to_file(item)
                file.path = path.join({ opts.cwd, file.path })
                vim.ui.input({
                    prompt = "New path: ",
                    default = file.path,
                }, function(target)
                    if not target or target == file.path then
                        return
                    end
                    vim.uv.fs_rename(file.path, target)
                    local bufnr = vim.fn.bufnr(file.path)
                    if bufnr ~= -1 then
                        local wins = vim.fn.win_findbuf(bufnr)
                        for _, win in ipairs(wins) do
                            local buf = vim.api.nvim_create_buf(false, false)
                            vim.api.nvim_win_set_buf(win, buf)
                        end
                        vim.api.nvim_buf_delete(bufnr, {
                            force = true,
                        })
                    end
                    opts.focused[opts.cwd] = vim.fn.fnamemodify(vim.fs.normalize(target), ":t")
                    M.browse({
                        clipboard = opts.clipboard,
                        cwd = opts.cwd,
                        focused = opts.focused,
                        hidden = opts.hidden,
                    })
                end)
            end,
            field_index = "{}",
            reload = true,
        },
        delete = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                vim.ui.input({
                    prompt = string.format("Delete %s file(s)? [y/n] ", vim.tbl_count(selected)),
                }, function(input)
                    if input ~= "y" then
                        return
                    end
                    for _, item in ipairs(selected) do
                        local file = path.entry_to_file(item)
                        file.path = path.join({ opts.cwd, file.path })
                        local stat = vim.uv.fs_stat(file.path)
                        if not stat then
                            return
                        end
                        if stat.type == "directory" then
                            vim.fn.delete(file.path, "rf")
                        else
                            vim.uv.fs_unlink(file.path)
                        end
                        local bufnr = vim.fn.bufnr(file.path)
                        if bufnr ~= -1 then
                            local wins = vim.fn.win_findbuf(bufnr)
                            for _, win in ipairs(wins) do
                                local buf = vim.api.nvim_create_buf(false, false)
                                vim.api.nvim_win_set_buf(win, buf)
                            end
                            vim.api.nvim_buf_delete(bufnr, {
                                force = true,
                            })
                        end
                    end
                    opts.focused[opts.cwd] = nil
                    M.browse({
                        clipboard = opts.clipboard,
                        cwd = opts.cwd,
                        focused = opts.focused,
                        hidden = opts.hidden,
                    })
                end)
            end,
            reload = true,
        },
        copy = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                local msg = string.format("Clipboard updated with %s file(s)", vim.tbl_count(selected))
                vim.notify(msg)
                M.browse({
                    clipboard = {
                        action = "copy",
                        files = vim.tbl_map(function(item)
                            local file = path.entry_to_file(item)
                            file.path = path.join({ opts.cwd, file.path })
                            return file
                        end, selected),
                    },
                    cwd = opts.cwd,
                    focused = opts.focused,
                    hidden = opts.hidden,
                })
            end,
            reload = true,
        },
        cut = {
            fn = function(selected, opts)
                if vim.tbl_isempty(selected) then
                    return
                end
                local msg = string.format("Clipboard updated with %s file(s)", vim.tbl_count(selected))
                vim.notify(msg)
                M.browse({
                    clipboard = {
                        action = "cut",
                        files = vim.tbl_map(function(item)
                            local file = path.entry_to_file(item)
                            file.path = path.join({ opts.cwd, file.path })
                            return file
                        end, selected),
                    },
                    cwd = opts.cwd,
                    focused = opts.focused,
                    hidden = opts.hidden,
                })
            end,
            reload = true,
        },
        paste = {
            fn = function(_, opts)
                if vim.isnil(opts.clipboard) or vim.tbl_isempty(opts.clipboard.files) then
                    return
                end
                for _, file in ipairs(opts.clipboard.files) do
                    local stat = vim.uv.fs_stat(file.path)
                    if stat then
                        local target = path.join({ opts.cwd, path.basename(file.path) })
                        if opts.clipboard.action == "copy" then
                            vim.uv.fs_copyfile(file.path, target)
                        end
                        if opts.clipboard.action == "cut" then
                            vim.uv.fs_rename(file.path, target)
                        end
                        local bufnr = vim.fn.bufnr(file.path)
                        if bufnr ~= -1 then
                            local wins = vim.fn.win_findbuf(bufnr)
                            for _, win in ipairs(wins) do
                                local buf = vim.api.nvim_create_buf(false, false)
                                vim.api.nvim_win_set_buf(win, buf)
                            end
                            vim.api.nvim_buf_delete(bufnr, {
                                force = true,
                            })
                        end
                    end
                end
                M.browse({
                    clipboard = nil,
                    cwd = opts.cwd,
                    focused = opts.focused,
                    hidden = opts.hidden,
                })
            end,
            reload = true,
        },
    },
}

M.hijack_netrw = function()
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            pcall(vim.api.nvim_clear_autocmds, {
                group = "FileExplorer",
            })
        end,
        once = true,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(args)
            if not vim.api.nvim_buf_is_valid(args.buf) then
                return
            end
            local bufname = vim.api.nvim_buf_get_name(args.buf)
            if vim.fn.isdirectory(bufname) == 0 then
                return
            end
            if bufname == vim.g.netrw_bufname then
                return
            end
            vim.g.netrw_bufname = bufname
            vim.api.nvim_set_option_value("bufhidden", "wipe", {
                buf = args.buf,
            })
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then
                    pcall(vim.api.nvim_buf_delete, args.buf, {
                        force = true,
                    })
                end
                M.browse({
                    cwd = bufname,
                })
            end)
        end,
        group = vim.api.nvim_create_augroup("FzfLuaFileBrowser", {
            clear = true,
        }),
    })
end

M.setup = function(opts)
    if not fzf then
        return
    end
    fzf.register_extension(
        "file_browser",
        M.browse,
        vim.tbl_deep_extend("keep", opts or {}, {
            actions = {
                ["default"] = M.defaults.actions.open,
                ["ctrl-s"] = M.defaults.actions.split,
                ["ctrl-v"] = M.defaults.actions.split_vertical,
                ["ctrl-g"] = M.defaults.actions.go_to_parent,
                ["ctrl-e"] = M.defaults.actions.go_to_cwd,
                ["ctrl-h"] = M.defaults.actions.toggle_hidden,
                ["ctrl-a"] = M.defaults.actions.create,
                ["ctrl-r"] = M.defaults.actions.rename,
                ["ctrl-d"] = M.defaults.actions.delete,
                ["ctrl-y"] = M.defaults.actions.copy,
                ["ctrl-t"] = M.defaults.actions.cut,
                ["ctrl-o"] = M.defaults.actions.paste,
            },
            color_icons = true,
            dir_icon = fzf.defaults.dir_icon,
            file_icons = true,
            fzf_args = "--sync --bind change:first",
            fzf_opts = {
                ["--multi"] = true,
                ["--scheme"] = "path",
            },
            hidden = true,
        }),
        true
    )
    if opts.hijack_netrw then
        M.hijack_netrw()
    end
end

M.browse = function(opts)
    opts = vim.deepcopy(opts or {})
    opts = fzf.config.normalize_opts(opts, "file_browser")
    if not opts then
        return
    end
    opts.focused = opts.focused or {}
    local cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.uv.cwd()
    if not opts.cwd then
        opts.focused[cwd] = vim.fn.expand("%:t:h")
    end
    opts.cwd = cwd
    local items = vim.fs.dir(opts.cwd)
    local files = vim.iter(items)
        :map(function(name, type)
            local file = {
                name = name,
                path = path.join({ opts.cwd, name }),
                type = type,
            }
            return file
        end)
        :filter(function(file)
            return opts.hidden or file.name:sub(1, 1) ~= "."
        end)
        :totable()
    table.sort(files, function(a, b)
        if a.type ~= b.type then
            return a.type == "directory"
        end
        return a.name < b.name
    end)
    for i, file in ipairs(files) do
        if opts.focused[opts.cwd] == file.name then
            opts.fzf_args = table.concat({
                opts.fzf_args,
                string.format("--bind start:pos\\(%s\\)", i),
            }, " ")
            break
        end
    end
    local contents = function(callback)
        for _, file in ipairs(files) do
            local parts = { file.name }
            if opts.file_icons then
                local icon = opts.dir_icon
                local hl = vim.api.nvim_get_hl(0, {
                    link = false,
                    name = opts.hls.dir_icon,
                })
                local color = string.format("#%06x", hl.fg)
                if file.type == "file" then
                    icon, color = devicons.get_devicon(file.path)
                end
                if opts.color_icons then
                    icon = utils.ansi_from_rgb(color, icon)
                end
                table.insert(parts, 1, icon)
            end
            local entry = table.concat(parts, utils.nbsp)
            callback(entry)
        end
        callback()
    end
    fzf.fzf_exec(contents, opts)
end

return M
