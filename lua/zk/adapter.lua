-- The interface between zk.nvim and zk
local config = require("zk").config_values

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
--           if config.debug then
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
--           if config.debug then
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
--           if config.debug then
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

function M.new(title)
  local sub_cmd = string.format("%s new", base_cmd)
  local cmd = sub_cmd

  if title ~= nil and title ~= "" then
    cmd = string.format("%s --print-path --title %s", sub_cmd, title)
  end

  vim.fn.jobstart(
    cmd,
    {
      on_stdout = function(j, d, e)
        if config.debug then
          print(
            string.format("[zk.nvim] on_stdout -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
          )
        end

        if d[1] ~= nil and d[1] ~= "" then
          vim.api.nvim_out_write("[zk.nvim] new note created: " .. d[1])

          -- FIXME: defaulting to opening in a new vsplit for now..
          vim.cmd(string.format("vnew %s", d[1]))
        end

        return
      end,
      on_stderr = function(j, d, e)
        if config.debug then
          print(
            string.format("[zk.nvim] on_stderr -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
          )
        end

        if d == 0 then
          vim.api.nvim_out_write("[zk.nvim] new note created")
          return
        end

        vim.api.nvim_err_writeln("[zk.nvim] failed to create new note -> " .. d[1])
      end,
      on_exit = function(j, d, e)
        if config.debug then
          print(
            string.format("[zk.nvim] on_exit -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
          )
        end

        if d == 0 then
          vim.api.nvim_out_write("[zk.nvim] new note created")
          return
        end

        vim.api.nvim_err_writeln("[zk.nvim] failed to create new note")
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
