local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local make_entry = require("telescope.make_entry")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local open_note = function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    actions.close(prompt_bufnr)
    vim.cmd(":edit " .. selection.filename)
end

local telescope_zk_notes = function(opts)
    opts = opts or {}

    local lookup_keys = {
        display = 2,
        ordinal = 1,
        value = 1,
        filename = 3,
    }

    local mt_string_entry = {
        __index = function(t, k)
            return rawget(t, rawget(lookup_keys, k))
        end
    }

    -- TODO: can I use _G.zk_config here?
    opts.entry_maker = function(line)
        local tmp_table = vim.split(line, "\t");
        return setmetatable({
            line,
            tmp_table[2],
            _G.zk_config.default_notebook_path .. "/" .. tmp_table[1],
        }, mt_string_entry)
    end

    pickers.new({}, {
        prompt_title = "Zk notes",
        finder = finders.new_oneshot_job(vim.tbl_flatten({ "zk", "list", "-q", "-P", "--format", "{{ path }}\t{{ title }}" }), opts),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer(opts),
        attach_mappings = function(_, map)
            action_set.select:replace(open_note)
            return true
        end
    }):find()
end

return require("telescope").register_extension({
    exports = {
        zk_notes = telescope_zk_notes,
    }
})
