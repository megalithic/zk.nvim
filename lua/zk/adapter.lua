-- The interface between zk.nvim and zk
local util = require("zk.util")

local M = {}
local base_cmd = "zk"

function M.init()
end

function M.new(args)
  local opts = {
    title = "",
    action = "vnew",
    notebook = "",
    -- tags = {},
    content = "",
    start_insert_mode = true
  }

  opts = util.extend(args, opts)
  local action = opts.action
  -- TODO: extract string parsing and cleaning to a function
  -- NOTE: vim.fn.fnameescape doesn't seem to do what we want with that cleansing of
  -- strings.
  local title = string.gsub(opts.title, "|", "&") -- vim.fn.fnameescape(opts.title)
  local content = opts.content -- vim.fn.fnameescape(opts.content)
  local notebook = opts.notebook -- vim.fn.fnameescape(opts.notebook)

  local cmd = string.format("%s new --no-input --print-path $ZK_NOTEBOOK_DIR/%s", base_cmd, notebook)

  if title ~= nil and title ~= "" then
    cmd = string.format('%s --title "%s"', cmd, title)
  end

  if content ~= nil and content ~= "" then
    cmd = string.format('echo "%s" | %s', content, cmd)
  end

  if zk_config.debug then
    print(
      string.format(
        "[zk.nvim] opts/args -> action: %s, title: %s, content: %s, notebook: %s, cmd: %s",
        vim.inspect(action),
        vim.inspect(title),
        vim.inspect(content),
        vim.inspect(notebook),
        vim.inspect(cmd)
      )
    )
  end

  vim.fn.jobstart(
    cmd,
    {
      on_stdout = function(j, d, e)
        if type(d) == "table" and d[1] ~= nil and d[1] ~= "" then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] on_stdout -> j: %s, d: %s, e: %s",
                vim.inspect(j),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
            vim.api.nvim_out_write("[zk.nvim] new note created: " .. d[1])
          end

          -- handle starting insert mode at the bottom of our file
          local start_insert_mode = ""
          if opts.start_insert_mode then
            start_insert_mode = " | startinsert | normal GA"
          end

          vim.cmd(string.format("%s %s %s", action, d[1], start_insert_mode))
        end
      end,
      on_stderr = function(j, d, e)
        if (type(d) == "table" and d[1] ~= nil and d[1] ~= "") then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] on_stderr -> j: %s, d: %s, e: %s",
                vim.inspect(j),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
          end

          vim.api.nvim_err_writeln("[zk.nvim] (on_stderr) failed to create new note -> " .. d[1])
          return
        end
      end,
      on_exit = function(j, d, e)
        if (type(d) == "table" and d[1] ~= nil and d[1] ~= "") then
          if zk_config.debug then
            print(
              string.format("[zk.nvim] on_exit -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
            )
          end

          vim.api.nvim_err_writeln("[zk.nvim] (on_exit) failed to create new note -> " .. d[1])
          return
        end
      end
    }
  )
end

function M.list()
end

function M.index()
end

local function handle_fzf(opts)
  local fzf = require("fzf")

  -- TODO: is there another one of ensuring our searches, results, and
  -- previews occur in the correct `pwd` and `cwd`.
  vim.cmd("cd " .. zk_config.default_notebook_path)

  local preview = "head -n $FZF_PREVIEW_LINES -- {-1}"
  local cmd = string.format("%s list --quiet --format path", base_cmd)

  if opts.notebook ~= nil and opts.notebook ~= "" then
    cmd = string.format("%s %s", cmd, opts.notebook)
  end

  if opts.tags ~= nil and opts.tags ~= "" then
    cmd = string.format("%s --tag %s", cmd, opts.tags)
  end

  if opts.query ~= nil and opts.query ~= "" then
    cmd = string.format("%s --match %s", cmd, vim.fn.fnameescape(opts.query))
  end

  if vim.fn.executable("bat") == 1 then
    -- NOTE: 5 is the number that prevents overflow of the preview window when using bat
    preview = "bat -p --line-range=:$(($FZF_PREVIEW_LINES - 5)) --color always -- {-1}"
  end

  coroutine.wrap(
    function()
      local choices =
        fzf.fzf(cmd, ("--ansi --preview=%s --expect=ctrl-s,ctrl-t,ctrl-v --multi"):format(vim.fn.shellescape(preview)))

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
end

function M.search(args)
  local opts = {
    notebook = "",
    query = "",
    tags = ""
  }
  opts = util.extend(args, opts)

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
