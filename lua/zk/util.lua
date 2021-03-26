local M = {}

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

-- function M.nmap(mode, _rhs, _lhs)
--   local key = vim.api.nvim_replace_termcodes(lhs, true, false, true)
--   vim.api.nvim_feedkeys(key, "n", true)
-- end

function M.extend(opts, target)
  opts = opts or {}
  if next(opts) == nil then
    return
  end

  for key, value in pairs(opts) do
    if target[key] == nil then
      error(string.format("[zk.nvim] The given key, `%s`, does not exist in config values.", key))
      return
    end
    if type(target[key]) == "table" then
      for k, v in pairs(value) do
        target[key][k] = v
      end
    else
      target[key] = value
    end
  end

  return target
end

return M
