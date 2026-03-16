local actions = require("fzf-lua-file-browser.actions")

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

return M
