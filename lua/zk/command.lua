-- The interface to provide the available commands via lua to nvim

local command = {}
local adapter = require('zk.adapter')

local subcommands = {
  new = adapter.new,
  search = adapter.search,
  backlink = adapter.backlink
}

function command.command_list()
  return vim.tbl_keys(subcommands)
end

function command.load_command(cmd,...)
  local args = {...}
  if next(args) ~= nil then
    subcommands[cmd](args[1])
  else
    subcommands[cmd]()
  end
end

return command
