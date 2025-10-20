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
```

To customize the actions you may do the following:

```lua
local file_browser = require("fzf-lua-file-browser")
local actions = require("fzf-lua-file-browser.actions")
file_browser.setup({
    actions = {
        ["ctrl-l"] = actions.rename,
        -- or use your own callback
        ["ctrl-m"] = function(selected, opts)
            if next(selected) then
                print(selected[1])
            end
            file_browser.browse(opts) -- use this instruction to resume
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
vim.keymap.set("n", "<leader>fe", "<Cmd>FzfLua file_browser<CR>", { silent = true })
```

From there on you can use the keybindings to interact with your files.

## Special thanks

Thanks [ibhagwan](https://github.com/ibhagwan) for the neovim plugin and [junegunn](https://github.com/junegunn) for the tool that made this possible.
