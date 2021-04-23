-- The interface between zk.nvim and zk
local Job = require("plenary.job")
local utils = require("zk.utils")

local M = {}
local base_cmd = "zk"

local function start_job(cmd, args, cwd, on_exit)
  Job:new {
    command = cmd,
    args = args,
    cwd = cwd,
    on_exit = vim.schedule_wrap(
      on_exit
      -- function()
      --   local created_note = file_path:exists()
      --   if created_note then
      --     M.buffer_update_on_lines(link.bufnr, link.row, link.row + 1)
      --     vim.cmd("write")
      --     vim.cmd("edit " .. file_path:expand())
      --     local last_line = vim.api.nvim_buf_line_count(0)

      --     -- To insert lines at a given index, set `start` and `end` to the
      --     -- same index. To delete a range of lines, set `replacement` to
      --     -- an empty array.
      --     vim.api.nvim_buf_set_lines(
      --       0,
      --       last_line,
      --       last_line,
      --       false,
      --       {
      --         "",
      --         ("# %s"):format(link.zettelid)
      --       }
      --     )
      --     vim.api.nvim_set_current_dir(zk_config.default_notebook_path:expand())
      --   else
      --     debug("Could not create new note..")
      --   end
      -- end
    )
  }:start()
end

-- Handles raw zk command; basically acts as a pass-through to zk directly.
-- TODO: handle a table of args param at some point? presently relies on
-- building up a cmd string
function M.raw_zk(cmd, args, on_done)
  if cmd == "" or cmd == nil then
    cmd = base_cmd
  end

  if args ~= nil then
    local job =
      start_job(
      cmd,
      args,
      "",
      function()
        on_done()
      end
    )

    job = start_job(cmd, args, "", on_done)

    -- TODO: figure out what gets returned
    utils.debug({msg = "job started and run", val = job})
    return job
  else
    local function get_lines_from_file(file)
      local t = {}
      for v in file:lines() do
        table.insert(t, v)
      end
      return t
    end

    -- note, this is ALL blocking presently
    -- see nvim-fzf for ideas on how to async
    local output_tmpname = vim.fn.tempname()
    os.execute(string.format("%s > %s", cmd, vim.fn.shellescape(output_tmpname)))
    local f = io.open(output_tmpname)
    local output = get_lines_from_file(f)
    f:close()
    vim.fn.delete(output_tmpname)

    -- do things when our cmd execution is complete
    -- FIXME: we assume we had/have output to pass through and a return..
    on_done(output)

    return output
  end
end

function M.new(args)
  local opts = {
    title = "",
    action = "vnew",
    notebook = "",
    content = "",
    start_insert_mode = true
  }

  opts = utils.extend(opts, args)
  local cmd = string.format("%s new --no-input --print-path", base_cmd)
  local cmd_args = {"new", "--no-input", "--print-path"}

  if opts.notebook ~= nil and opts.notebook ~= "" then
    cmd = string.format("%s $ZK_NOTEBOOK_DIR/%s", cmd, opts.notebook)
    table.insert(cmd_args, string.format("$ZK_NOTEBOOK_DIR/%s", opts.notebook))
  end

  if opts.title ~= nil and opts.title ~= "" then
    cmd = string.format('%s --title "%s"', cmd, opts.title)
    table.insert(cmd_args, string.format("--title %s", opts.title))
  end

  -- FIXME figure out how to handle this with a plenary Job; without botching
  -- notes with existing content...
  --
  if opts.content ~= nil and opts.content ~= "" then
    cmd = string.format('echo "%s" | %s', opts.content, cmd)
  end

  if zk_config.debug then
    utils.debug(
      "new note opts/args -> action: %s, title: %s, content: %s, notebook: %s, cmd: %s",
      {
        vim.inspect(opts.action),
        vim.inspect(opts.title),
        vim.inspect(opts.content),
        vim.inspect(opts.notebook),
        vim.inspect(cmd_args),
        vim.inspect(cmd)
      }
    )
  end

  return M.raw_zk(
    cmd,
    nil, -- for now we're not going to use our cmd_args for a Job
    function(output)
      -- bail out of doing anything with this buffer if no action;
      -- assumes the caller will handle next steps with the returned file path
      if opts.action == nil or opts.action == "" then
        return nil
      end

      -- handle starting insert mode at the bottom of our file
      local start_insert_mode = ""

      if opts.start_insert_mode then
        start_insert_mode = " | startinsert | normal Go"
      end

      -- TODO: this assumes our success output is our file name
      vim.cmd(string.format("%s %s %s", opts.action, output[1], start_insert_mode))
      vim.cmd("w | e") -- this should force the buffer to reattach the LS client to the buffer
    end
  )[1] -- again, we assume this is always a single item table
end

function M.list()
end

function M.index()
end

local function handle_fzf(opts)
  local fzf = require("fzf")

  -- TODO: is there another one of ensuring our searches, results, and
  -- previews occur in the correct `pwd` and `cwd`.
  -- vim.cmd("cd " .. zk_config.default_notebook_path)
  vim.api.nvim_set_current_dir(zk_config.default_notebook_path)

  local preview = "head -n $FZF_PREVIEW_LINES -- {-1}"
  local cmd = string.format("%s list --quiet --format path", base_cmd)

  if opts.tags ~= nil and opts.tags ~= "" then
    cmd = string.format("%s --tag %s", cmd, opts.tags)
  end

  if opts.query ~= nil and opts.query ~= "" then
    cmd = string.format("%s --match %s", cmd, vim.fn.fnameescape(opts.query))
  end

  if opts.notebook ~= nil and opts.notebook ~= "" then
    cmd = string.format("%s %s", cmd, opts.notebook)
  end

  if vim.fn.executable("bat") == 1 then
    -- NOTE: 5 is the number that prevents overflow of the preview window when using bat
    preview = "bat -p --line-range=:$(($FZF_PREVIEW_LINES - 5)) --color always {}"
    opts.fzf_opts["--preview"] = ("--preview=%s"):format(vim.fn.shellescape(preview))
  end

  local fzf_opts = table.concat(opts.fzf_opts, " ")

  coroutine.wrap(
    function()
      local choices = fzf.fzf(cmd, fzf_opts)

      if not choices then
        return
      end

      local vimcmd
      if choices[1] == "ctrl-t" then
        vimcmd = "tabnew"
      elseif choices[1] == "ctrl-v" then
        vimcmd = "vnew"
      elseif choices[1] == "ctrl-s" then
        vimcmd = "new"
      else
        vimcmd = "e"
      end

      for i = 2, #choices do
        vim.cmd(vimcmd .. " " .. vim.fn.fnameescape(choices[i]))
      end
    end
  )()
end

local function handle_telescope(_)
  vim.api.nvim_err_writeln("[zk.nvim] telescope.nvim support not yet implemented.")

  return
end

function M.search(args)
  if type(args) == "string" then
    args = {query = args}
  else
    args = args or {}
  end

  -- TODO: allow for user-defined fzf_opts..
  local fzf_opts =
    args.fzf_opts or
    {
      "--delimiter=\x01",
      "--tiebreak=begin",
      "--ansi",
      -- "--exact",
      "--tabstop=4",
      "--height=100%",
      "--layout=reverse",
      -- Make sure the path and titles are always visible
      "--no-hscroll",
      -- Don't highlight search terms
      "--color=hl:-1,hl+:-1",
      "--preview-window=wrap",
      "--expect=ctrl-s,ctrl-t,ctrl-v"
    }
  local opts = {
    notebook = "",
    query = "",
    tags = "",
    fzf_opts = fzf_opts
  }
  opts = utils.extend(opts, args)

  if zk_config.fuzzy_finder == "fzf" and vim.fn.executable("fzf") then
    return handle_fzf(opts)
  else
    return handle_telescope(opts)
  end
end

function M.create_link()
end

function M.backlink()
end

return M
