local util = require("zk.util")

local M = {}

function M.setup_keymaps()
  if zk_config.default_keymaps and vim.bo.filetype == "markdown" then
    -- FIXME: `<CR>` seems to break completion popups confirmation
    vim.api.nvim_set_keymap(
      "x",
      "<CR>",
      "<cmd>lua require('zk.command').create_note_link()<cr>",
      -- "<cmd>lua require('zk.util').conditional_cr()<cr>",
      {noremap = true, silent = false}
    )
    vim.api.nvim_set_keymap(
      "n",
      "<CR>",
      "<cmd>lua require('zk.command').create_note_link({title = vim.fn.expand('<cword>')})<cr>",
      -- "<cmd>lua require('zk.util').conditional_cr({title = vim.fn.expand('<cword>')})<cr>",
      {noremap = true, silent = false}
    )
  -- vim.api.nvim_set_keymap("n", "<leader>zf", "<c-u>ZkSearch<space>", {noremap = true, silent = false})
  -- vim.cmd([[nnoremap <leader>zf :<c-u>ZkSearch<space>]])
  end
end

function M.setup(args)
  args = args or {}
  local defaults = {
    debug = false,
    log = true,
    default_keymaps = true,
    default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "",
    fuzzy_finder = "fzf", -- or "telescope"
    link_format = "markdown" -- or "wiki"
  }

  _G.zk_config = util.extend(defaults, args)

  vim.cmd([[command! ZkInstall :lua require('zk.command').install_zk()]])

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it.")
    return
  end

  vim.cmd([[command! -nargs=1 ZkSearch call luaeval('require("zk.command").search(_A)', <f-args>)]])
end

return M
