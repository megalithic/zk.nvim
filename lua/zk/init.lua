local util = require("zk.util")

local M = {}

function M.ft_setup()
  if zk_config.enable_default_keymaps and vim.bo.filetype == "markdown" then
    -- FIXME: for some reason i get _no_ table passed through on v/s/x mode binding
    vim.api.nvim_set_keymap(
      "x",
      "<CR>",
      "<cmd>lua require('zk.command').create_note_link({})<cr>",
      {noremap = true, silent = false}
    )
    vim.api.nvim_set_keymap(
      "n",
      "<CR>",
      "<cmd>lua require('zk.command').create_note_link({title = vim.fn.expand('<cword>')})<cr>",
      {noremap = true, silent = false}
    )
  end
end

function M.setup(opts)
  local config_values = {
    debug = false,
    log = true,
    enable_default_keymaps = true,
    default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "",
    fuzzy_finder = "fzf", -- or "telescope"
    link_format = "markdown" -- or "wikilink"
  }

  _G.zk_config = util.extend(opts, config_values)

  vim.cmd("command! ZkInstall :lua require('zk.command').install_zk()")

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it.")
    return
  end
end

return M
