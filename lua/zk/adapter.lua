-- The interface between zk.nvim and zk
local util = require("zk.util")

local M = {}
local base_cmd = "zk"

-- function M.init(dir)
--   local sub_cmd = string.format("%s init", base_cmd)
--   local cmd = string.format("%s init", base_cmd)

--   if dir ~= nil and dir ~= "" then
--     cmd = string.format("%s %s", sub_cmd, dir)

--     vim.fn.jobstart(
--       cmd,
--       {
--         on_stdout = function(j, d, e)
--           if zk_config.debug then
--             print(
--               string.format(
--                 "[zk.nvim] on_stdout -> j: %s, d: %s, e: %s",
--                 vim.inspect(j),
--                 vim.inspect(d),
--                 vim.inspect(e)
--               )
--             )
--           end

--           if d[1] ~= nil and d[1] ~= "" then
--             vim.api.nvim_out_write("[zk.nvim] new note created: " .. d[1])

--             -- FIXME: defaulting to opening in a new vsplit for now..
--             vim.cmd(string.format("vnew %s", d[1]))
--           end

--           return
--         end,
--         on_stderr = function(j, d, e)
--           if zk_config.debug then
--             print(
--               string.format(
--                 "[zk.nvim] on_stderr -> j: %s, d: %s, e: %s",
--                 vim.inspect(j),
--                 vim.inspect(d),
--                 vim.inspect(e)
--               )
--             )
--           end

--           if d == 0 then
--             vim.api.nvim_out_write("[zk.nvim] new note created")
--             return
--           end

--           vim.api.nvim_err_writeln("[zk.nvim] failed to create new note -> " .. d[1])
--         end,
--         on_exit = function(j, d, e)
--           if zk_config.debug then
--             print(
--               string.format("[zk.nvim] on_exit -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
--             )
--           end

--           if d == 0 then
--             vim.api.nvim_out_write("[zk.nvim] new note created")
--             return
--           end

--           vim.api.nvim_err_writeln("[zk.nvim] failed to create new note")
--         end
--       }
--     )
--   end
-- end

function M.new(args)
  local opts = {
    title = "",
    action = "vnew",
    notebook = "",
    -- tags = {},
    content = "",
    start_insert_mode = true
  }

  opts = util.extend(args, opts)
  local action = opts.action
  local title = opts.title
  local content = opts.content
  local notebook = opts.notebook

  local cmd = string.format("%s new --no-input --print-path %s", base_cmd, notebook)

  if title ~= nil and title ~= "" then
    cmd = string.format('%s --title "%s"', cmd, title)
  end

  if content ~= nil and content ~= "" then
    cmd = string.format('print "%s" | ', content) .. cmd
  end

  vim.fn.jobstart(
    cmd,
    {
      on_stdout = function(j, d, e)
        if type(d) == "table" and d[1] ~= nil and d[1] ~= "" then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] on_stdout -> j: %s, d: %s, e: %s",
                vim.inspect(j),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
            vim.api.nvim_out_write("[zk.nvim] new note created: " .. d[1])
          end

          -- handle starting insert mode at the bottom of our file
          local start_insert_mode = ""
          if opts.start_insert_mode then
            start_insert_mode = " | startinsert | normal GA"
          end

          vim.cmd(string.format("%s %s %s", action, d[1], start_insert_mode))
        end
      end,
      on_stderr = function(j, d, e)
        if (type(d) == "table" and d[1] ~= nil and d[1] ~= "") then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] on_stderr -> j: %s, d: %s, e: %s",
                vim.inspect(j),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
          end

          vim.api.nvim_err_writeln("[zk.nvim] (on_stderr) failed to create new note -> " .. d[1])
          return
        end
      end,
      on_exit = function(j, d, e)
        if (type(d) == "table" and d[1] ~= nil and d[1] ~= "") then
          if zk_config.debug then
            print(
              string.format("[zk.nvim] on_exit -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
            )
          end

          vim.api.nvim_err_writeln("[zk.nvim] (on_exit) failed to create new note -> " .. d[1])
          return
        end
      end
    }
  )
end

function M.list()
end

function M.index()
end

function M.search()
end

function M.create_link()
end

function M.backlink()
end

return M
