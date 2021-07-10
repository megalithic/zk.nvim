local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local Job = require'plenary.job'

local new_note = function(title)
    local args = {"new", "-p", "-t", title}
    local cwd = _G.zk_config.default_notebook_path
    local path

    local job = Job:new({
        command = "zk",
        args = args,
        cwd = cwd,
        on_stdout = function(_, line)
          if not line or line == "" then
            return
          end
          path = line
        end,
    })

    job:sync()
    vim.cmd(":edit " .. path)
end

local open_note = function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    if selection == nil then
        local title = action_state.get_current_line(prompt_bufnr)
        actions.close(prompt_bufnr)
        new_note(title)
    else
        actions.close(prompt_bufnr)
        vim.cmd(":edit " .. selection.filename)
    end
end

local create_entry_maker = function()
    local lookup_keys = {
        ordinal = 1,
        value = 1,
        display = 2,
        filename = 3,
    }

    local mt_string_entry = {
        __index = function(t, k)
            return rawget(t, rawget(lookup_keys, k))
        end
    }
    -- TODO: can I use _G.zk_config here?
    return function(line)
        local tmp_table = vim.split(line, "\t");
        return setmetatable({
            line,
            tmp_table[2] or "",
            _G.zk_config.default_notebook_path .. "/" .. tmp_table[1] or "",
        }, mt_string_entry)
    end
end

local telescope_zk_notes = function(opts)
    opts = opts or {}

    opts.entry_maker = create_entry_maker()

    local cmd = { "zk", "list", "-q", "-P", "--format", "{{ path }}\t{{ title }}" }

    pickers.new({}, {
        prompt_title = "Zk notes",
        finder = finders.new_oneshot_job(vim.tbl_flatten(cmd), opts),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer(opts),
        attach_mappings = function(_, map)
            action_set.select:replace(open_note)
            return true
        end
    }):find()
end

local telescope_zk_grep = function(opts)
    opts = opts or {}

    local cwd = _G.zk_config.default_notebook_path
    opts.cwd = opts.cwd or cwd
    opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
    opts.entry_maker = create_entry_maker()

    local notebook = '.'
    if opts.notebook ~= nil then
        notebook = opts.notebook
    end

    local zk_notes_grep = finders.new_job(function(prompt)
        local basic_cmd = {
            "zk",
            "list",
            "--footer", "\n",
            "-q",
            "-P",
            "--format", "{{ path }}\t{{ title }}",
            notebook
        }
        if not prompt or prompt == "" then
            return basic_cmd
        end
        local parts = vim.split(prompt, "%s")
        for i, part in pairs(parts) do
            parts[i] = part .. "*"
        end
        prompt = table.concat(parts, " ")
        return vim.tbl_flatten({basic_cmd, {"-m", prompt }})
      end,
      opts.entry_maker,
      opts.max_results,
      opts.cwd
    )

    pickers.new(opts, {
      prompt_title = "Zk notes (full)",
      finder = zk_notes_grep,
      previewer = conf.file_previewer(opts),
      sorter = sorters.empty(),
      attach_mappings = function(_, map)
        action_set.select:replace(open_note)
        return true
      end
    }):find()
end

return require("telescope").register_extension({
    exports = {
        zk_notes = telescope_zk_notes,
        zk_grep = telescope_zk_grep,
    }
})
