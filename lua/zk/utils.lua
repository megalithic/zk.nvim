local M = {}

local function msg_prefixer(opts)
  local prefix_str = "[zk.nvim]"

  if type(opts) == "string" then
    return string.format("%s %s", prefix_str, opts)
  else
    return string.format("%s %s -> %s", prefix_str, opts.msg, opts.val)
  end
end

-- Print to cmd line, always
function M.print(msg)
  vim.api.nvim_out_write(msg_prefixer(msg) .. "\n")
end

-- Always print error message to cmd line
function M.err(msg)
  vim.api.nvim_err_writeln(msg_prefixer(msg))
end

-- Generic logging
function M.log(...)
  if zk_config.log then
    vim.api.nvim_out_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.error(...)
  if zk_config.log then
    if zk_config.debug then
      print(table.concat(...))
    end
    vim.api.nvim_error_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.inspect(val)
  if zk_config.log and zk_config.debug then
    print(vim.inspect(val))
  end
end

function M.debug(opts)
  if zk_config.log and zk_config.debug then
    print(msg_prefixer(opts))
  end
end

function M.extend(opts, target)
  opts = vim.tbl_extend("force", opts, target)
  return opts
end

return M
