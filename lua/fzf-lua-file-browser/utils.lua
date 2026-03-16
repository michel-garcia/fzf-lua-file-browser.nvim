local fzf_utils = require("fzf-lua.utils")

local config = require("fzf-lua-file-browser.config")
local filesystem = require("fzf-lua-file-browser.filesystem")
local state = require("fzf-lua-file-browser.state")

local M = {}

M.make_item = function(file)
    local _, icons = pcall(require, "nvim-web-devicons")
    local name = file.is_dir and string.format("%s/", file.name) or file.name
    local icon, color = nil, nil
    if config.opts.file_icons and icons then
        if file.is_dir then
            icon = config.opts.dir_icon
            if config.opts.dir_icon_hl then
                local highlight = vim.api.nvim_get_hl(0, {
                    name = config.opts.dir_icon_hl,
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
        fzf_utils.nbsp
    )
    if config.opts.color_icons and color then
        icon = fzf_utils.ansi_from_rgb(color, icon)
    end
    local label = table.concat(
        vim.tbl_filter(function(value)
            return value
        end, { icon, name }),
        fzf_utils.nbsp
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
    if not state.hidden then
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

return M
