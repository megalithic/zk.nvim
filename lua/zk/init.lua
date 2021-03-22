_G.zk_util = require("zk.util")

local M = {}

M.config_values = {
  debug = false,
  log = true,
  enable_default_keymaps = true,
  root_target = ".zk",
  default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or ""
}

local extend_config = function(opts)
  opts = opts or {}
  if next(opts) == nil then
    return
  end
  for key, value in pairs(opts) do
    if M.config_values[key] == nil then
      error(string.format("[zk.nvim] The given key, `%s`, does not exist in config values.", key))
      return
    end
    if type(M.config_values[key]) == "table" then
      for k, v in pairs(value) do
        M.config_values[key][k] = v
      end
    else
      M.config_values[key] = value
    end
  end
end

function M.setup(opts)
  -- safely merges passed in config values; use in the rest of the plugin with:
  -- `local config = require('zk').config_values`; NOTE: not global
  extend_config(opts)

  -- set our public api, optional zk
  vim.cmd("command! ZkInstall :lua require('zk.command').install_zk()")

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it.")
    return
  end

  -- set our public api, requiring zk
  -- vim.cmd("command! -nargs=? ZkInit :lua require('zk.command').init('<f-args>')")
  vim.cmd("command! -nargs=? ZkNew :lua require('zk.command').new('<f-args>')")

  -- if M.config_values.enable_default_keymaps then
  --   util.map('n', '<')
  -- end
end

return M
