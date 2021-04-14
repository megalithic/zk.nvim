local M = {}

local function safe_close(handle)
  if not vim.loop.is_closing(handle) then
    handle:close()
  -- vim.loop.close(handle)
  end
end

local function spawn(cmd, opts, input, onexit)
  local handle, pid
  -- open a new pipe for stdout
  local stdout = vim.loop.new_pipe(false)
  -- open a new pipe for stderr
  local stderr = vim.loop.new_pipe(false)
  handle, pid =
    vim.loop.spawn(
    cmd,
    vim.tbl_extend("force", opts, {stdio = {stdout, stderr}}),
    vim.schedule_wrap(
      function()
        print("schedulewrapping")
      end,
      function(code, signal)
        -- call the exit callback with the code and signal
        onexit(code, signal)
        -- stop reading data to stdout
        stdout:read_stop()
        -- vim.loop.read_stop(stdout)
        -- stop reading data to stderr
        stderr:read_stop()
        -- vim.loop.read_stop(stderr)
        -- safely shutdown stdout pipe
        safe_close(stdout)
        -- safely shutdown stderr pipe
        safe_close(stderr)
        -- safely shutdown child process
        safe_close(handle)
        print("done doing things..")
      end
    )
  )
  print("handle: ", vim.inspect(handle))
  print("pid: ", pid)

  -- read child process output to stdout
  vim.loop.read_start(stdout, input.stdout)
  -- read child process output to stderr
  vim.loop.read_start(stderr, input.stderr)
end

M.call = function(cmd, args, handlers)
  local generic_handler = function(err, data)
    if err then
      if zk_config.debug then
        print(string.format("[zk.nvim] call_stderr -> %s", err))
      -- vim.api.nvim_err_writeln("[zk.nvim] call_stderr failed -> " .. err_out)
      end
    end
    if data then
      if zk_config.debug then
        local data_out = vim.inspect(data)
        print(string.format("[zk.nvim] call_stdout -> %s", data_out))
      -- vim.api.nvim_out_write("[zk.nvim] call_stdout: " .. data_out)
      end
    end
  end
  local default_handlers = {
    stdout = function(err, data)
      generic_handler(err, data)
    end,
    stderr = function(err, data)
      generic_handler(err, data)
    end,
    onexit = function(exit_code, signal)
      if zk_config.debug then
        print(string.format("[zk.nvim] call_onexit -> %s (%s)", exit_code, signal))
        -- vim.api.nvim_out_write("[zk.nvim] call_onexit: " .. exit_code_out)
        return exit_code
      end
    end
  }

  handlers = vim.tbl_extend("force", handlers, default_handlers)

  return spawn(
    cmd,
    {
      args = args
    },
    {stdout = handlers.stdout, stderr = handlers.stderr},
    handlers.onexit
  )
end

M.cast = function(cmd, _args, handler)
  vim.fn.jobstart(
    cmd,
    {
      on_stdout = function(pid, d, e)
        if type(d) == "table" and d[1] ~= nil and d[1] ~= "" then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] new on_stdout -> pid: %s, d: %s, e: %s",
                vim.inspect(pid),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
            vim.api.nvim_out_write("[zk.nvim] process_cmd success: " .. d[1])
          end

          if handler ~= nil and type(handler) == "function" then
            handler(d)
          end
        end
      end,
      on_stderr = function(pid, d, e)
        if (type(d) == "table" and d[1] ~= nil and d[1] ~= "") then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] new on_stderr -> pid: %s, d: %s, e: %s",
                vim.inspect(pid),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
          end

          vim.api.nvim_err_writeln("[zk.nvim] (on_stderr) process_cmd failed -> " .. d[1])
          return
        end
      end,
      on_exit = function(pid, d, e)
        if (type(d) == "table" and d[1] ~= nil and d[1] ~= "") then
          if zk_config.debug then
            print(
              string.format(
                "[zk.nvim] new on_exit -> pid: %s, d: %s, e: %s",
                vim.inspect(pid),
                vim.inspect(d),
                vim.inspect(e)
              )
            )
          end

          vim.api.nvim_err_writeln("[zk.nvim] (on_exit) process_cmd failed -> " .. d[1])
          return
        end
      end
    }
  )
end

return M
