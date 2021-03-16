_G.zk_util = require("zk.util")

local M = {}
M.default_config = {
  debug = false,
  root_target = ".zk",
  default_notebook_path = ""
}

local extend_config = function(opts)
  opts = opts or {}
  if next(opts) == nil then
    return
  end
  for key, value in pairs(opts) do
    if M.default_config[key] == nil then
      error(string.format("[zk.nvim] The given key, %s, does not exist in config values", key))
      return
    end
    if type(M.default_config[key]) == "table" then
      for k, v in pairs(value) do
        M.default_config[key][k] = v
      end
    else
      M.default_config[key] = value
    end
  end
end

function M.init(opts)
  extend_config(opts)

  vim.cmd("command! -nargs=? ZkNew :lua require('zk.command').new('<f-args>')")
  vim.cmd("command! ZkInstall :lua require('zk.command').install_zk()")

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it")
    return
  end
end

return M
