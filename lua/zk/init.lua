local util = require("zk.util")

local M = {}

function M.setup(opts)
  local config_values = {
    debug = false,
    log = true,
    enable_default_keymaps = true,
    default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "",
    fuzzy_finder = "fzf"
  }

  _G.zk_config = util.extend(opts, config_values)

  vim.cmd("command! ZkInstall :lua require('zk.command').install_zk()")

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it.")
    return
  end

  vim.cmd([[command! -nargs=1 ZkCreateNoteLink call luaeval('require("zk.command").create_note_link(_A)', <f-args>)]])

  vim.api.nvim_set_keymap(
    "x",
    "<CR>",
    -- "<esc>:exe('ZkCreateNoteLink '.expand('<cword'))<cr>",
    "<cmd>lua require('zk.command').create_note_link(vim.fn.expand('<cword>'))<cr>",
    {noremap = true, expr = true, silent = false}
  )
  vim.api.nvim_set_keymap(
    "n",
    "<CR>",
    -- [[<esc><cmd>("ZkCreateNoteLink ".expand("<cword"))<cr>]],
    "<cmd>lua require('zk.command').create_note_link(vim.fn.expand('<cword>'))<cr>",
    {noremap = true, expr = true, silent = false}
  )

  -- FIXME:
  -- error when called: `E15: Invalid expression: <80><fd>hlua require('zk.command').create_note_link(vim.fn.expand('<cword>'))^M`
end

return M
