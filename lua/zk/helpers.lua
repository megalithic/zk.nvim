local utils = require("zk.utils")
local debug = utils.debug

local M = {}
M.namespace = vim.api.nvim_create_namespace("zk.nvim")

local function msub(line, s, f)
  return line:sub(s, f) .. vim.fn.strcharpart(line:sub(f + 1), 0, 1)
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

--- Get all extmarks in buffer
-- List of [extmark_id, row, col] tuples in "traversal order"
---@param bufnr number
---@param ns_id number
---@return table
function M.buf_all_extmarks(bufnr, ns_id)
  return vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {details = true})
end

---Get all extmarks in line
---@param bufnr number
---@param ns_id number
---@param lnum number
function M.line_all_extmarks(bufnr, ns_id, lnum)
  return vim.api.nvim_buf_get_extmarks(bufnr, ns_id, {lnum, 0}, {lnum, -1}, {details = true})
end

function M.buffer_update_on_lines(bufnr, first_line, last_line_updated)
  local ns_id = M.namespace

  local lines = vim.api.nvim_buf_get_lines(bufnr, first_line, last_line_updated, false)

  if first_line < last_line_updated then
    for i = first_line, last_line_updated - 1 do
      local links = {}
      for link in M.link_scanner(lines[i - first_line + 1]) do
        table.insert(links, link)
      end
      for _, link in pairs(links) do
        local start_col, end_col, zettelid, zettel_exists = link.col, link.end_col, link.zettelid, link.exists
        local extmark_id
        local extmarks_in_line = M.line_all_extmarks(bufnr, ns_id, i)
        for _, e in pairs(extmarks_in_line) do
          if start_col - 1 == e[3] or end_col == e[4]["end_col"] then
            extmark_id = e[1]
            break
          else
            extmark_id = nil
          end
        end
        -- local zettel_path = config.neuron_dir:joinpath(zettelid .. ".md")
        -- local zettel_exists = zettel_path:exists()
        -- local zettel_exists = link.zettel_data
        local hl_group
        if zettel_exists then
          hl_group = "Green"
        else
          hl_group = "Red"
        end
        vim.api.nvim_buf_set_extmark(
          bufnr,
          ns_id,
          i,
          start_col - 1,
          {
            id = extmark_id,
            end_col = end_col,
            hl_group = hl_group
            -- virt_text = {{link.str, hl_group}},
            -- virt_text_pos = "overlay"
          }
        )
      end
      local extmarks_in_line = M.line_all_extmarks(bufnr, ns_id, i)
      local count_extmarks = #extmarks_in_line or 0
      local count_links = #links or 0
      while count_extmarks > count_links do
        if count_links == 0 then
          for _, e in pairs(extmarks_in_line) do
            vim.api.nvim_buf_del_extmark(bufnr, ns_id, e[1])
            count_extmarks = count_extmarks - 1
          end
        end
        for _, e in pairs(extmarks_in_line) do
          local found_match
          for _, link in pairs(links) do
            if link.col - 1 == e[3] and link.end_col == e[4]["end_col"] then
              found_match = true
              break
            else
              found_match = false
            end
          end
          if not found_match then
            vim.api.nvim_buf_del_extmark(bufnr, ns_id, e[1])
            count_extmarks = count_extmarks - 1
          end
        end
      end
    end
  end
  local all_extmarks = M.buf_all_extmarks(bufnr, ns_id)
  for _, e in pairs(all_extmarks) do
    -- Delete extmarks if they are at position 0,0
    if e[3] == e[4]["end_col"] then
      vim.api.nvim_buf_del_extmark(bufnr, ns_id, e[1])
    end

    --- Delete extmarks if they are too short, e.g "[[]]"
    if (e[4]["end_col"] - e[3]) <= 4 then
      vim.api.nvim_buf_del_extmark(bufnr, ns_id, e[1])
    end
  end
end

---Scan line for links
-- https://github.com/srid/neuron/blob/448a3d7d6ee19d0a9c52b29fee7b6c6b8ae6b2d9/neuron/src/lib/Neuron/Zettelkasten/ID.hs#L82
-- local allowed_special_chars = {"_", "-", ".", " ", ",", ";", "(", ")", ":", '"', "'", "@"}
---@param line string|table
---@param pos any
---@param opts any
---@return function
function M.link_scanner(line, pos, opts)
  opts = opts or {}
  assert(type(opts) == "table", "link_scanner() param opts is not a table")
  pos = pos or 1

  return function()
    while true do
      local link = {string.find(line, '(([#]?)(%[%[[^%[%]]-))([%w%d% %_%-%.%,%;%(%)%:%"%\'%@]+)((%]%])([#]?))', pos)}
      print("link found?", vim.inspect(link))
      local start, finish = link[1], link[2]
      if not start then
        break
      end

      -- local zettelid = link[6]

      -- local zettel_path = require("neuron_v2.helpers").zettel_path(zettelid)
      -- local zettel_exists = zettel_path:exists()

      -- TODO(frandsoh): Should I move this somewhere else?
      -- if the link has a # at the start and end, ignore them
      if link[3]:len() == 3 and link[7]:len() == 3 then
        start = start + 1
        finish = finish - 1
      end

      local str = line:sub(start, finish)

      pos = finish + 1
      return {
        str = str,
        row = opts.row,
        exists = false,
        zettelid = "zk123",
        bufnr = opts.bufnr,
        col = start,
        end_col = finish
      }
    end
  end
end

-- based on
-- https://github.com/notomo/curstr.nvim/blob/fa35837da5412d1a216bd832f827464d7ac7f0aa/lua/curstr/core/cursor.lua#L20
function M.get_cword()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local pattern = ("\\v\\k*%%%sc\\k+"):format(pos[2] + 1)
  local str, start_byte = unpack(vim.fn.matchstrpos(line, pattern))
  if start_byte == -1 then
    return
  end
  local after_part = vim.fn.strpart(line, start_byte)
  local start = #line - #after_part
  local finish = start + #str
  return {
    str = str,
    start = start,
    finish = finish
  }
end

function M.get_visual()
  local s = vim.fn.getpos("'<")
  local f = vim.fn.getpos("'>")
  assert(s[2] == f[2], "Can't make multiline links")
  local str = msub(vim.api.nvim_get_current_line(), s[3], f[3] - 1)
  local start = s[3] - 1
  local finish = start + str:len()

  return {
    str = str,
    start = start,
    finish = finish
  }
end

function M.get_link_under_cursor()
  local line = vim.api.nvim_get_current_line() -- Gets the current line.
  local pos = vim.api.nvim_win_get_cursor(0) -- {1,0} indexed {row, col}

  -- row - 1 to make it work with nvim_buf_get_lines... i think :)
  local row, col, bufnr = pos[1] - 1, pos[2] + 1, vim.api.nvim_get_current_buf()

  debug("is there a link under the curos?", M.link_scanner(line, nil, {row = row, bufnr = bufnr}))
  for v in M.link_scanner(line, nil, {row = row, bufnr = bufnr}) do
    debug("v is a thing", v)

    if col >= v.col and col <= v.end_col then
      debug("should return v", v)
      return v
    end
  end
end

function M.open()
  local link = M.get_link_under_cursor()
  if not link then
    return
  end
  -- TODO(frandsoh): Update to use link.exists and helpers.zettel_path
  -- local file_name = link.zettelid .. ".md"
  -- local file_path = config.neuron_dir:joinpath(file_name)
  -- local is_new = not file_path:exists()

  debug("is new?", {link})

  if is_new then
    debug("is new!", link)
    -- vim.cmd [[write]]
    -- require("zk.command").new()

    return
  end
  -- vim.cmd [[write]]
  -- vim.cmd("e " .. file_path:expand())
  -- vim.api.nvim_set_current_dir(config.neuron_dir:expand())
end

function M.create_link(visual)
  local word

  if visual then
    word = M.get_visual()
  else
    word = M.get_cword()
  end

  if not word then
    return
  end

  local pos = vim.fn.getpos(".") -- returns [bufnum, lnum, col, off]
  local buf = pos[1] -- bufnum
  local start_row = pos[2] - 1 -- lnum
  local start_col = word.start
  local end_row = start_row
  local end_col = word.finish
  -- local replacement = ("[[%s]]"):format(word.str)
  local replacement = ("[[%s]]"):format(word.str)

  -- To insert text at a given index, set `start` and `end` ranges
  -- to the same index. To delete a range, set `replacement` to an
  -- array containing an empty string, or simply an empty array.
  vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, {replacement})
end

function M.open_or_create()
  if M.get_link_under_cursor() then
    debug("should open the link!", M.get_link_under_cursor())
    M.open()
  else
    debug("should create a new link!")
    M.create_link()
  end
end

return M
