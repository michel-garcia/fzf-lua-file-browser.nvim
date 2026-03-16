local fzf = require("fzf-lua")

local config = require("fzf-lua-file-browser.config")
local previewer = require("fzf-lua-file-browser.previewer")
local state = require("fzf-lua-file-browser.state")
local utils = require("fzf-lua-file-browser.utils")

local M = {}

M.browse = function(opts)
    opts = opts or {}
    state.cwd = opts.cwd or vim.fn.expand("%:p:h") or vim.loop.cwd()
    if not opts.cwd then
        state.active = vim.fn.expand("%:t:h")
    end
    local fzf_args = {
        "--sync",
        "--bind change:first",
    }
    if config.opts.cwd_header then
        local path = vim.fn.pathshorten(state.cwd)
        local arg = string.format("--header=%s", path)
        table.insert(fzf_args, arg)
    end
    local prompt = config.opts.prompt
    if config.opts.cwd_prompt then
        local path = vim.fn.pathshorten(state.cwd)
        prompt = string.format("%s/", path)
    end
    local items = utils.get_items(state.cwd)
    state.files = {}
    local lines = {}
    for i, item in ipairs(items) do
        table.insert(lines, item.label)
        state.files[item.key] = item.file
        if item.file.name == state.active then
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
        actions = config.opts.actions,
        browser = M,
        cwd = state.cwd,
        fzf_args = table.concat(fzf_args, " "),
        previewer = previewer,
        prompt = prompt,
        winopts = {
            title = " File Browser ",
        },
    })
end

return M
