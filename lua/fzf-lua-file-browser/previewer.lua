local fzf_previewer_builtin = require("fzf-lua.previewer.builtin")

local M = fzf_previewer_builtin.buffer_or_file:extend()

function M:new(o, opts, fzf_win)
    M.super.new(self, o, opts, fzf_win)
    setmetatable(self, M)
    return self
end

M.populate_preview_buf = function(self, key)
    local browser = require("fzf-lua-file-browser")
    local file = browser.state.files[key] or nil
    if not file then
        return
    end
    local buf = self:get_tmp_buffer()
    local lines = {}
    if file.is_dir then
        local items = browser.get_items(file.path)
        for _, item in ipairs(items) do
            table.insert(lines, item.key)
        end
    else
        local handle = io.open(file.path, "r")
        if handle then
            for line in handle:lines() do
                table.insert(lines, line)
            end
            handle:close()
        end
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    self:set_preview_buf(buf)
    self.win:update_preview_title(string.format(" %s ", file.name))
end

return M
