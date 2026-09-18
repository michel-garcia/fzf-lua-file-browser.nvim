local fzf = require("fzf-lua")
local devicons = require("fzf-lua.devicons")
local path = require("fzf-lua.path")
local utils = require("fzf-lua.utils")

local M = {}

M.setup = function(opts)
    if not fzf then
        return
    end
    fzf.register_extension(
        "file_browser",
        M.browse,
        vim.tbl_deep_extend("keep", opts or {}, {
            actions = {
                ["default"] = {
                    fn = function(selected, o)
                        if vim.tbl_isempty(selected) then
                            return
                        end
                        local item = table.remove(selected)
                        local file = path.entry_to_file(item)
                        file.path = path.join({ o.cwd, file.path })
                        local stat = vim.uv.fs_stat(file.path)
                        if not stat then
                            return
                        end
                        if stat.type == "directory" then
                            o.cwd = file.path
                            return
                        end
                        local win = vim.api.nvim_get_current_win()
                        vim.api.nvim_win_close(win, true)
                        vim.schedule(function()
                            fzf.actions.file_edit({
                                file.path,
                            }, o)
                        end)
                    end,
                    field_index = "{}",
                    postfix = "clear-query",
                    reload = true,
                },
                ["ctrl-s"] = {
                    fn = function(selected, o)
                        if vim.tbl_isempty(selected) then
                            return
                        end
                        local item = table.remove(selected)
                        local file = path.entry_to_file(item)
                        file.path = path.join({ o.cwd, file.path })
                        local stat = vim.uv.fs_stat(file.path)
                        if not stat or stat.type == "directory" then
                            return
                        end
                        local win = vim.api.nvim_get_current_win()
                        vim.api.nvim_win_close(win, true)
                        vim.schedule(function()
                            fzf.actions.file_split({
                                file.path,
                            }, o)
                        end)
                    end,
                    field_index = "{}",
                    reload = true,
                },
                ["ctrl-v"] = {
                    fn = function(selected, o)
                        if vim.tbl_isempty(selected) then
                            return
                        end
                        local item = table.remove(selected)
                        local file = path.entry_to_file(item)
                        file.path = path.join({ o.cwd, file.path })
                        local stat = vim.uv.fs_stat(file.path)
                        if not stat or stat.type == "directory" then
                            return
                        end
                        local win = vim.api.nvim_get_current_win()
                        vim.api.nvim_win_close(win, true)
                        vim.schedule(function()
                            fzf.actions.file_vsplit({
                                file.path,
                            }, o)
                        end)
                    end,
                    field_index = "{}",
                    reload = true,
                },
                ["ctrl-g"] = {
                    fn = function(_, o)
                        o.cwd = path.parent(o.cwd)
                    end,
                    postfix = "clear-query",
                    reload = true,
                },
                ["ctrl-e"] = {
                    fn = function(_, o)
                        o.cwd = vim.uv.cwd()
                    end,
                    postfix = "clear-query",
                    reload = true,
                },
                ["ctrl-h"] = {
                    fn = function(_, o)
                        o.hidden = not o.hidden
                    end,
                    reload = true,
                },
                ["ctrl-a"] = {
                    fn = function(_, o)
                        vim.ui.input({
                            prompt = "New path: ",
                            default = path.add_trailing(o.cwd),
                        }, function(target)
                            if not target then
                                return
                            end
                            local stat = vim.uv.fs_stat(target)
                            if stat then
                                return
                            end
                            if string.sub(target, -1) == "/" then
                                local mode = tonumber("755", 8)
                                vim.uv.fs_mkdir(target, mode)
                                return
                            end
                            local mode = tonumber("644", 8)
                            local handle = vim.uv.fs_open(target, "w", mode)
                            vim.uv.fs_close(handle)
                        end)
                    end,
                    postfix = "clear-query",
                    reload = true,
                },
                ["ctrl-r"] = {
                    fn = function(selected, o)
                        if vim.tbl_isempty(selected) then
                            return
                        end
                        local item = table.remove(selected)
                        local file = path.entry_to_file(item)
                        file.path = path.join({ o.cwd, file.path })
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
                        end)
                    end,
                    field_index = "{}",
                    postfix = "clear-query",
                    reload = true,
                },
                ["ctrl-d"] = {
                    fn = function(selected, o)
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
                                file.path = path.join({ o.cwd, file.path })
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
                        end)
                    end,
                    postfix = "clear-query",
                    reload = true,
                },
                ["ctrl-y"] = {
                    fn = function(selected, o)
                        if vim.tbl_isempty(selected) then
                            return
                        end
                        local msg = string.format("Clipboard updated with %s file(s)", vim.tbl_count(selected))
                        vim.notify(msg)
                        o.clipboard = {
                            action = "copy",
                            files = vim.tbl_map(function(item)
                                local file = path.entry_to_file(item)
                                file.path = path.join({ o.cwd, file.path })
                                return file
                            end, selected),
                        }
                    end,
                    reload = true,
                },
                ["ctrl-t"] = {
                    fn = function(selected, o)
                        if vim.tbl_isempty(selected) then
                            return
                        end
                        local msg = string.format("Clipboard updated with %s file(s)", vim.tbl_count(selected))
                        vim.notify(msg)
                        o.clipboard = {
                            action = "move",
                            files = vim.tbl_map(function(item)
                                local file = path.entry_to_file(item)
                                file.path = path.join({ o.cwd, file.path })
                                return file
                            end, selected),
                        }
                    end,
                    reload = true,
                },
                ["ctrl-o"] = {
                    fn = function(_, o)
                        if vim.isnil(o.clipboard) or vim.tbl_isempty(o.clipboard.files) then
                            return
                        end
                        for _, file in ipairs(o.clipboard.files) do
                            local stat = vim.uv.fs_stat(file.path)
                            if stat then
                                local target = path.join({ o.cwd, path.basename(file.path) })
                                if o.clipboard.action == "copy" then
                                    vim.uv.fs_copyfile(file.path, target)
                                end
                                if o.clipboard.action == "move" then
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
                        o.clipboard = nil
                    end,
                    reload = true,
                },
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
end

M.browse = function(opts)
    opts = vim.deepcopy(opts or {})
    opts = fzf.config.normalize_opts(opts, "file_browser")
    if not opts then
        return
    end
    opts.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.uv.cwd()
    local contents = function(callback)
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
