-- The interface to provide the available commands via lua to nvim

local adapter = require("zk.adapter")
local util = require("zk.util")

local M = {}

local zk_repo_path = "github.com/mickael-menu/zk@HEAD"

local function call_go_cmd()
  local cmd = {"go", "get", "-tags", '"fts5 icu"', "-u", zk_repo_path}
  vim.fn.jobstart(
    cmd,
    {
      on_exit = function(_, d, _)
        if d == 0 then
          vim.api.nvim_out_write("[zk.nvim] latest zk installed")
          return
        end
        vim.api.nvim_err_writeln("[zk.nvim] failed to install zk")
      end
    }
  )
end

function M.install_zk()
  if not vim.fn.executable("go") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] golang not installed. It must be installed before continuing.")
  end

  if vim.fn.executable("zk") == 1 then
    local answer = vim.fn.input("[zk.nvim] latest zk already installed, do you want update? y/n -> ")
    answer = string.lower(answer)
    while answer ~= "y" and answer ~= "n" do
      answer = vim.fn.input("[zk.nvim] please answer y or n -> ")
      answer = string.lower(answer)
    end

    vim.api.nvim_out_write("\n")
    vim.cmd([[redraw]])
    if answer == "n" then
      return
    end

    vim.api.nvim_out_write("[zk.nvim] updating zk...\n")
  else
    print("[zk.nvim] installing zk...")
  end

  call_go_cmd()
end

function M.new(...)
  return adapter.new(...)
end

function M.search(...)
  local fzf_exists, _ = pcall(require, "fzf")
  if zk_config.fuzzy_finder == "fzf" and not fzf_exists then
    vim.api.nvim_err_writeln(
      "[zk.nvim] in order to use fzf, https://github.com/vijaymarupudi/nvim-fzf must be installed."
    )
    return
  end

  local telescope_exists, _ = pcall(require, "telescope")
  if zk_config.fuzzy_finder == "telescope" and not telescope_exists then
    vim.api.nvim_err_writeln(
      "[zk.nvim] in order to use telescope.nvim, https://github.com/nvim-telescope/telescope.nvim must be installed."
    )
    return
  end

  return adapter.search(...)
end

function M.create_note_link(args)
  -- FIXME/TODO: need to create the note link based on the current notebook; and
  -- set that as a default instead of `""`.
  args = args or {}
  local opts = {
    title = "",
    action = "vnew",
    notebook = "",
    open_note_on_creation = true
  }

  opts = util.extend(opts, args)

  -- we came in by way of v/x/s modes, so we should grab the selection
  if opts.title == "" then
    local selection = util.get_visual_selection()
    opts.title = selection.contents
  end

  print("create_note_link(title) -> ", opts.title)

  if opts.title ~= nil and opts.title ~= "" then
    local new_note_path = M.new({title = opts.title, notebook = opts.notebook, action = ""})

    -- don't reformat the text if we're already in a `[]` pair
    if not util.is_linkified(opts.title) then
      local link_output = util.make_link_text(opts.title, vim.fn.fnameescape(new_note_path))
      util.replace_selection_with_link_text(opts.title, link_output)
    end

    if opts.open_note_on_creation then
      vim.cmd(string.format("%s %s", opts.action, new_note_path))
    end
  end
end

return M
