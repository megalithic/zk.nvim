-- The interface between zk.nvim and zk

local M = {}

function M.new(title)
  local cmd = "zk new"

  if title ~= nil and title ~= "" then
    cmd = string.format("zk new --print-path --title %s", title)
  end

  vim.fn.jobstart(
    cmd,
    {
      on_stdout = function(j, d, e)
        print(
          string.format("[zk.nvim] on_stdout -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
        )

        vim.api.nvim_out_write("[zk.nvim] new note created: " .. d[1])

        -- FIXME: defaulting to opening in a new vsplit for now..
        vim.cmd(string.format("vnew %s", d[1]))

        return
      end,
      on_stderr = function(j, d, e)
        print(
          string.format("[zk.nvim] on_stderr -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e))
        )

        if d == 0 then
          vim.api.nvim_out_write("[zk.nvim] new note created")
          return
        end

        vim.api.nvim_err_writeln("[zk.nvim] failed to create new note -> " .. d[1])
      end,
      on_exit = function(j, d, e)
        print(string.format("[zk.nvim] on_exit -> j: %s, d: %s, e: %s", vim.inspect(j), vim.inspect(d), vim.inspect(e)))

        if d == 0 then
          vim.api.nvim_out_write("[zk.nvim] new note created")
          return
        end

        vim.api.nvim_err_writeln("[zk.nvim] failed to create new note")
      end
    }
  )
end

function M.search()
end

function M.create_link()
end

function M.backlink()
end

return M
