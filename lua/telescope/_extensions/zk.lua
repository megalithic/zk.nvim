local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local Job = require'plenary.job'

local edit_note = function(path)
    vim.cmd(":edit " .. path)
    vim.cmd "norm! G"
end

local new_note = function(title)
    local args = {"new", "-p", "-t", title}
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
    edit_note(path)
end

local create_note = function(prompt_bufnr)
    local title = action_state.get_current_line(prompt_bufnr)
    actions.close(prompt_bufnr)
    new_note(title)
end

local open_note = function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    if selection == nil then
        local title = action_state.get_current_line(prompt_bufnr)
        actions.close(prompt_bufnr)
        new_note(title)
    else
        actions.close(prompt_bufnr)
        edit_note(selection.filename)
    end
end

local create_entry_maker = function()
    local lookup_keys = {
        ordinal = 2,
        value = 1,
        display = 2,
        filename = 3,
    }

    local mt_string_entry = {
        __index = function(t, k)
            return rawget(t, rawget(lookup_keys, k))
        end
    }

    return function(line)
        local tmp_table = vim.split(line, "\t");
        return setmetatable({
            line,
            tmp_table[2],
            tmp_table[1],
        }, mt_string_entry)
    end
end

local telescope_zk_notes = function(opts)
    opts = opts or {}

    opts.entry_maker = create_entry_maker()

    local cmd = {
        "zk",
        "list",
        "-q",
        "-P",
        "--format",
        "{{ abs-path }}\t{{ title }}",
    }

    pickers.new({}, {
        prompt_title = "Zk notes",
        finder = finders.new_oneshot_job(vim.tbl_flatten(cmd), opts),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer(opts),
        attach_mappings = function(_, map)
            action_set.select:replace(open_note)
            map('i', '<C-e>', create_note)
            map('n', '<C-e>', create_note)
            return true
        end
    }):find()
end

local telescope_zk_backlinks = function(opts)
    opts = opts or {}

    local lookup_keys = {
        display = 2,
        ordinal = 2,
        value = 1,
        filename = 3,
        text = 4,
    }

    local mt_string_entry = {
        __index = function(t, k)
            return rawget(t, rawget(lookup_keys, k))
        end
    }

    local current = vim.fn.expand('%:t:r')

    opts.entry_maker = function(line)
        local tmp_table = vim.split(line, "\t");
        return setmetatable({
            line,
            tmp_table[2],
            tmp_table[1],
            current,
        }, mt_string_entry)
    end

    local search_cb_jump = function(self, bufnr, query)
        if not query then return end
        vim.api.nvim_buf_call(bufnr, function()
            pcall(vim.fn.matchdelete, self.state.hl_id, self.state.winid)
            vim.cmd "norm! gg"
            vim.fn.search(query, "W")
            vim.cmd "norm! zz"

            self.state.hl_id = vim.fn.matchadd('TelescopePreviewMatch', query)
        end)
    end

    local search_teardown = function(self)
        if self.state and self.state.hl_id then
            pcall(vim.fn.matchdelete, self.state.hl_id, self.state.hl_win)
            self.state.hl_id = nil
        end
    end

    local previewer = previewers.new_buffer_previewer {
        title = "Grep Preview",
        teardown = search_teardown,

        get_buffer_by_name = function(_, entry)
            return entry.filename
        end,

        define_preview = function(self, entry, status)
            local text = entry.text

            conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
                bufname = self.state.bufname,
                callback = function(bufnr)
                    search_cb_jump(self, bufnr, text)
                end
            })
        end
    }
    local notebook = '.'
    if opts.notebook ~= nil then
        notebook = opts.notebook
    end

    local cmd = {
        "zk",
        "list",
        "--footer", "\n",
        "--link-to", current,
        "-q",
        "-P",
        "--format", "{{ abs-path }}\t{{ title }}",
        notebook,
    }
    pickers.new({}, {
        prompt_title = "Zk backlinks",
        finder = finders.new_oneshot_job(vim.tbl_flatten(cmd), opts),
        sorter = conf.generic_sorter({}),
        previewer = previewer,
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
            "--format", "{{ abs-path }}\t{{ title }}",
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
        map('i', '<C-e>', create_note)
        map('n', '<C-e>', create_note)
        return true
      end
    }):find()
end

return require("telescope").register_extension({
    exports = {
        zk_notes = telescope_zk_notes,
        zk_grep = telescope_zk_grep,
        zk_backlinks = telescope_zk_backlinks,
    }
})
