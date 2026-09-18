# Fzf-Lua File Browser

A file browser/picker extension for [fzf-lua](https://github.com/ibhagwan/fzf-lua).

## Why

When working with mounted filesystems from a remote machine there is a noticeable delay from fzf indexing the files in the remote filesystem. This, depending on several factors, can be quite the long wait. The aim of `fzf-lua-file-browser` is to speed up navigating such file systems by indexing only one directory at the time while still keeping fuzzy finding usefulness.

This also brought the possibility to add simple file management capabilities, such as: creation, renaming, and deletion; which are available in this plugin and come in very useful.

## Installation

The only required dependency is [fzf-lua](https://github.com/ibhagwan/fzf-lua) itself.

Using [Packer](https://github.com/wbthomason/packer.nvim):

```lua
use({
    "michel-garcia/fzf-lua-file-browser.nvim",
    requires = {
        "ibhagwan/fzf-lua"
    }
})
```

Using [Lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "michel-garcia/fzf-lua-file-browser.nvim",
    dependencies = {
        "ibhagwan/fzf-lua"
    }
}
```

Using [vim.pack](https://neovim.io/doc/user/pack/#_plugin-manager):

```lua
vim.pack.add({
    "https://github.com/ibhagwan/fzf-lua"
    "https://github.com/michel-garcia/fzf-lua-file-browser.nvim",
})
```

## Setup

To initialize the plugin call `setup`:

```lua
require("fzf-lua-file-browser").setup()
```

Initialization is only necessary if you want to register the picker under the `FzfLua` command or override the default options.

## Options

Below is an example lua table of the available options and their respective default values:

```lua
{
    actions = {
        ["default"] = file_browser.defaults.actions.open,
        ["ctrl-s"] = file_browser.defaults.actions.split,
        ["ctrl-v"] = file_browser.defaults.actions.split_vertical,
        ["ctrl-g"] = file_browser.defaults.actions.go_to_parent,
        ["ctrl-e"] = file_browser.defaults.actions.go_to_cwd,
        ["ctrl-h"] = file_browser.defaults.actions.toggle_hidden,
        ["ctrl-a"] = file_browser.defaults.actions.create,
        ["ctrl-r"] = file_browser.defaults.actions.rename,
        ["ctrl-d"] = file_browser.defaults.actions.delete,
        ["ctrl-y"] = file_browser.defaults.actions.copy,
        ["ctrl-t"] = file_browser.defaults.actions.cut,
        ["ctrl-o"] = file_browser.defaults.actions.paste,
    },
    color_icons = true,
    file_icons = true,
    hidden = true,
    hijack_netrw = false,
}
```

Default mappings:

| Keymap | Action         | Description                                         |
| ------ | -------------- | --------------------------------------------------- |
| <cr>   | open           | Open file or browse directory                       |
| <c-s>  | split          | Open file in a horizontal split                     |
| <c-v>  | split_vertical | Open file in a vertical split                       |
| <c-g>  | go_to_parent   | Go to parent directory                              |
| <c-e>  | go_to_cwd      | Go to current working directory                     |
| <c-h>  | toggle_hidden  | Toggle hidden files                                 |
| <c-a>  | create         | Create file or directory                            |
| <c-r>  | rename         | Rename file or directory                            |
| <c-d>  | delete         | Delete selected files and/or directories            |
| <c-y>  | copy           | Copy selected files and/or directories to clipboard |
| <c-t>  | cut            | Cut selected files and/or directories to clipboard  |
| <c-o>  | paste          | Paste files and/or directories from clipboard       |

To add custom actions you may do the following:

```lua
local file_browser = require("fzf-lua-file-browser")
file_browser.setup({
    actions = {
        ["ctrl-f"] = function(selected, opts)
            if vim.tbl_isempty(selected) then
                return
            end
            local msg = string.format("Selected %s file(s)", vim.tbl_count(selected))
            vim.notify(msg)
        end,
    },
}
```

## Usage

Directly:

```lua
:FzfLua file_browser
-- or
:lua require("fzf-lua-file-browser").browse()
```

Using a keymap:

```lua
vim.keymap.set("n", "<leader>fe", "<Cmd>FzfLua file_browser<CR>")
```

From there on you can use the keybindings to interact with your files.

## Special thanks

Thanks [ibhagwan](https://github.com/ibhagwan) for the neovim plugin and [junegunn](https://github.com/junegunn) for the tool that made this possible.
