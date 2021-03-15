local M = {}

-- TODO: once commands can take functions as arguments natively remove this global
M.command_callbacks = {}

function M.command(args)
  local commands_table_name = "zk_util.command_callbacks"
  local nargs = args.nargs or 0
  local name = args[1]
  local rhs = args[2]
  local types = (args.types and type(args.types) == "table") and table.concat(args.types, " ") or ""

  if type(rhs) == "function" then
    table.insert(M.command_callbacks, rhs)
    rhs = string.format("lua %s[%d](%s)", commands_table_name, #M.command_callbacks, nargs == 0 and "" or "<f-args>")
  end

  vim.cmd(string.format("command! -nargs=%s %s %s %s", nargs, types, name, rhs))
end

return M
