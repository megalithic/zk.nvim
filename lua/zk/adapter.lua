-- The interface between our plugin and zk

local M = {}

function M.new(args)
  -- if args.title == nil then
  --   vim.fn.system(string.format("zk new --title %s %s", args.title, args.content))
  -- else
  --   vim.fn.system(string.format("zk new --title %s %s", args.title, args.content))
  -- end
end

function M.search()
end

function M.backlink()
end

return M
