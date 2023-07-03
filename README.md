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
        ["default"] = M.actions.edit_or_browse, -- edit file/browse directory
        ["ctrl-g"] = M.actions.go_to_parent, -- go to parent
        ["ctrl-w"] = M.actions.go_to_cwd, -- go to neovim cwd
        ["ctrl-h"] = M.actions.toggle_hidden, -- toggle hidden
        ["ctrl-e"] = M.actions.go_to_home, -- go to home
        ["ctrl-a"] = M.actions.create, -- create file/directory
        ["ctrl-r"] = M.actions.rename, -- rename file/directory
        ["ctrl-x"] = M.actions.delete -- delete file/directory
    },
    cwd = nil, -- current working directory, pass nil to use current
    hidden = false, -- whether or not to show hidden entries
    no_header = true, -- hide relative cwd header
    prompt = "File Browser> " -- prompt
}
```

To customize the actions you may do the following:

```lua
local file_browser = require("fzf-lua-file-browser")
file_browser.setup({
    actions = {
        ["ctrl-l"] = file_browser.actions.rename,
        -- or even use your own callback
        ["ctrl-m"] = function (selected, opts)
            if next(selected) then
                print(selected[1])
            end
            file_browser.browse(opts) -- use this instruction to resume
        end
    }
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
