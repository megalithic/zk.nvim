_G.zk_util = require("zk.util")

local M = {}

function M.init()
  vim.cmd("command! -nargs=? ZkNew :lua require('zk.command').new('<f-args>')")
  vim.cmd("command! ZkInstall :lua require('zk.command').install_zk()")

  if vim.fn.executable("zk") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] zk is not installed. Call :ZkInstall to install it")
    return
  end
end

return M
