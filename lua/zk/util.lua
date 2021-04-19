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

function M.get_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return {row - 1, col}
end

function M.get_visual_selection()
  local reg = "z"
  vim.cmd([[noau normal! "zy]])
  return {reg = reg, contents = vim.fn.getreg(reg)}
end

function M.set_visual_selection(reg)
  vim.cmd([[noau normal! "zy]])
  return {reg = reg, contents = vim.fn.getreg(reg)}
end

-- FIXME: this is a super-naive solution to figure out if we're in a `[]`
function M.is_linkified(str)
  local current_line = vim.fn.getline(".")
  local patterns = {
    "%[" .. str .. "%]"
    -- string.format("%{%s%}", str)
  }

  for _, pattern in ipairs(patterns) do
    return nil ~= current_line:match(pattern)
  end
end

function M.make_link_text(title, path)
  if title == nil or title == "" then
    return
  end

  if zk_config.link_format == "markdown" then
    return string.format("[%s](%s)", title, vim.fn.shellescape(path))
  elseif zk_config.link_format == "wiki" then
    -- TODO: look into supporting link | description:
    -- https://github.com/vimwiki/vimwiki/tree/dev#basic-markup
    return string.format("[[%s|%s]]", vim.fn.shellescape(path), title)
  end
end

function M.set_lines(bufnr, start_line, end_line, lines)
  return vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, true, lines)
end

function M.get_lines(bufnr, start_line, end_line)
  return vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, true)
end

function M.conditional_cr(opts)
  opts = opts or {}
  if vim.fn.pumvisible() == 0 then
    require("zk.command").create_note_link(opts)
  end
end

-- replaces all occurrences (in current buffer) of the given `o` string with the `n` string
function M.replace_selection_with_link_text(o, n)
  local bufnr = vim.api.nvim_get_current_buf()
  local offset = math.max(vim.fn.line("w0") - 1, 0)
  local range = math.min(vim.fn.line("w$"), vim.api.nvim_buf_line_count(bufnr))
  local lines = M.get_lines(bufnr, offset, range)

  for i, _ in ipairs(lines) do
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

return M
