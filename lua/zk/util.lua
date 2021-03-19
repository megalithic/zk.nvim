local M = {}
local config = require("zk").config_values

-- Print to cmd line, always
function M.print(msg)
  local txt = string.format("[zk.nvim] %s", msg)
  vim.api.nvim_out_write(txt .. "\n")
end

-- Always print error message to cmd line
function M.err(msg)
  local txt = string.format("[zk.nvim] %s", msg)
  vim.api.nvim_err_writeln(txt)
end

-- Generic logging
function M.log(...)
  if config.log then
    vim.api.nvim_out_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.error(...)
  if config.log then
    if config.debug then
      print(table.concat(...))
    end
    vim.api.nvim_error_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.inspect(val)
  if config.log and config.debug then
    print(vim.inspect(val))
  end
end

return M
