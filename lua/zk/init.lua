local util = require("zk.util")

local M = {}

function M.setup(opts)
  local config_values = {
    debug = false,
    log = true,
    enable_default_keymaps = true,
    root_target = ".zk",
    default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or ""
  }

  _G.zk_config = util.extend(opts, config_values)

  vim.cmd("command! ZkInstall :lua require('zk.command').install_zk()")

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it.")
    return
  end
end

return M
