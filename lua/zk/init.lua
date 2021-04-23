local utils = require("zk.utils")

local M = {}

function M.setup_keymaps()
  if zk_config.default_keymaps and vim.bo.filetype == "markdown" then
    local leader_keys = "gz"
    local function map(key, rhs)
      local lhs = string.format("%s%s", leader_keys, key)
      vim.api.nvim_set_keymap("n", lhs, rhs, {noremap = true, silent = false})
    end
    local function map_buf(key, rhs)
      local lhs = string.format("%s%s", leader_keys, key)
      vim.api.nvim_buf_set_keymap(0, "n", lhs, rhs, {noremap = true, silent = false})
    end
    -- FIXME: `<CR>` seems to break completion popups confirmation
    -- vim.api.nvim_set_keymap(
    --   "x",
    --   "<CR>",
    --   "<cmd>lua require('zk.command').create_note_link()<cr>",
    --   -- "<cmd>lua require('zk.util').conditional_cr()<cr>",
    --   {noremap = false, silent = false}
    -- )
    -- vim.api.nvim_set_keymap(
    --   "n",
    --   "<CR>",
    --   "<cmd>lua require('zk.command').create_note_link({title = vim.fn.expand('<cword>')})<cr>",
    --   -- "<cmd>lua require('zk.util').conditional_cr({title = vim.fn.expand('<cword>')})<cr>",
    --   {noremap = false, silent = false}
    -- )
    vim.api.nvim_buf_set_keymap(
      0,
      "n",
      "<CR>",
      "<cmd>lua require('zk.helpers').open_or_create()<CR>",
      {noremap = true, silent = false}
    )

    map_buf("<CR>", "<cmd>lua require('zk.helpers').create_link()<CR>")

    vim.api.nvim_buf_set_keymap(
      0,
      "v",
      "<CR>",
      ":<C-U>lua require('zk.helpers').create_link(true)<CR>",
      {noremap = true, silent = false}
    )

    map("f", ":<C-U>ZkSearch<space>")
    -- vim.api.nvim_set_keymap("n", "<leader>zf", "<c-u>ZkSearch<space>", {noremap = true, silent = false})
    vim.cmd([[nnoremap <leader>zf :<c-u>ZkSearch<space>]])
  end
end

function M.setup(opts)
  opts = opts or {}
  local config_values = {
    debug = false,
    log = true,
    default_keymaps = true,
    default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "",
    fuzzy_finder = "fzf", -- or "telescope"
    link_format = "wiki" -- or "wiki"
  }

  _G.zk_config = utils.extend(opts, config_values)

  vim.cmd([[command! ZkInstall :lua require('zk.command').install_zk()]])

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it.")
    return
  end

  vim.cmd([[command! -nargs=1 ZkSearch call luaeval('require("zk.command").search(_A)', <f-args>)]])
end

return M
