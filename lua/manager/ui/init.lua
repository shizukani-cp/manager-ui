local M = {}
local manager = require("manager.core")

local config = {
    keymaps = {
        update_all = "U",
        update_single = "u",
        load_single = "l",
        clean = "c",
        close = "q",
    }
}

local buf, win

function M.render()
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    local k = config.keymaps
    local header = string.format(" [ %s ]:UpdateAll | [ %s ]:Update | [ %s ]:Load | [ %s ]:Clean",
        k.update_all, k.update_single, k.load_single, k.clean)

    local lines = { header, string.rep("━", 70) }

    local ids = {}
    for id, _ in pairs(manager.plugins) do table.insert(ids, id) end
    table.sort(ids)

    for _, id in ipairs(ids) do
        local p = manager.plugins[id]
        local status = p.status or "new"
        table.insert(lines, string.format(" [%-10s] %s", status, id))
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.set_keymaps()
    local opts = { buffer = buf, silent = true }
    local k = config.keymaps

    local function get_id()
        return vim.api.nvim_get_current_line():match("%]%s+(.+)$")
    end

    vim.keymap.set('n', k.load_single, function()
        local id = get_id()
        if id then
            manager.load(id)
            print("Loaded: " .. id)
            M.render()
        end
    end, opts)

    vim.keymap.set('n', k.update_single, function()
        local id = get_id()
        if id then
            manager.update(id)
            M.render()
        end
    end, opts)

    vim.keymap.set('n', k.update_all, function()
        manager.update()
        M.render()
    end, opts)

    vim.keymap.set('n', k.clean, function()
        manager.clean()
        M.render()
    end, opts)

    vim.keymap.set('n', k.close, function()
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end, opts)
end

function M.open()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

    local w, h = math.floor(vim.o.columns * 0.7), math.floor(vim.o.lines * 0.7)
    win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = w,
        height = h,
        col = (vim.o.columns - w) / 2,
        row = (vim.o.lines - h) / 2,
        style = 'minimal',
        border = 'rounded',
        title = ' Plugin Manager '
    })

    M.set_keymaps()
    M.render()
end

function M.setup(user_config)
    if user_config and user_config.keymaps then
        config.keymaps = vim.tbl_deep_extend("force", config.keymaps, user_config.keymaps)
    end
    local success, command = pcall(require, "manager.command")
    if success then
        command.add_subcommand("ui", function(_) M.open() end)
    end
end

return M
