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

function M.extend(opts, target)
  opts = vim.tbl_extend("force", opts, target)
  return opts
end

M.get_visual_selection = function()
  local reg = "z"
  vim.cmd([[noau normal! "zy]])
  return {reg = reg, contents = vim.fn.getreg(reg)}
end

M.set_visual_selection = function(reg)
  vim.cmd([[noau normal! "zy]])
  return {reg = reg, contents = vim.fn.getreg(reg)}
end

M.make_link_text = function(title, path)
  if title == nil or title == "" then
    return
  end

  if zk_config.link_format == "markdown" then
    return string.format("[%s](%s)", title, vim.fn.shellescape(path))
  elseif zk_config.link_format == "wikilink" then
    return string.format("[[%s]]")
  end
end

function M.set_lines(bufnr, startLine, endLine, lines)
  return vim.api.nvim_buf_set_lines(bufnr, startLine, endLine, true, lines)
end

function M.get_lines(bufnr, startLine, endLine)
  return vim.api.nvim_buf_get_lines(bufnr, startLine, endLine, true)
end

M.replace_selection_with_link_text = function(o, n)
  local bufnr = vim.api.nvim_get_current_buf()
  local offset = math.max(vim.fn.line("w0") - 1, 0)
  local range = math.min(vim.fn.line("w$"), vim.api.nvim_buf_line_count(bufnr))
  local lines = M.get_lines(bufnr, offset, range)

  for i, _line in ipairs(lines) do
    local _, found = lines[i]:find(o)

    if found then
      lines[i] = lines[i]:gsub(o, n)
      local view = vim.fn.winsaveview()
      M.set_lines(bufnr, offset, range, lines)
      vim.fn.winrestview(view)

      vim.api.nvim_command("noautocmd :update")
    end

    ::continue::
  end
end

M.escape_chars = function(string)
  return string.gsub(
    string,
    "[%(|%)|\\|%[|%]|%-|%{%}|%?|%+|%*]",
    {
      ["\\"] = "\\\\",
      ["-"] = "\\-",
      ["("] = "\\(",
      [")"] = "\\)",
      ["["] = "\\[",
      ["]"] = "\\]",
      ["{"] = "\\{",
      ["}"] = "\\}",
      ["?"] = "\\?",
      ["+"] = "\\+",
      ["*"] = "\\*"
    }
  )
end
return M
