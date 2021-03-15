-- The interface between our plugin and zk

local adapter = {}

function adapter.new()
  -- zk_util.command {
  --   "ZkNew",
  --   function()
  --   end
  -- }
  zk_util.command {"ZkNew", [[<cmd>!zk new --title <q-args>]], nargs = 1}
  local title = vim.fn.input("Enter new Zk note title: ")
  if title and #title > 0 then
    vim.cmd "redraw" -- clear the input message we just added
    vim.cmd(string.format([[execute 'ZkNew %s']], title))
  end
  vim.cmd([[execute 'ZkNew']], title)
  -- vim.api.nvim_set_keymap("n", "<leader>zn", "<cmd>ZkNew<CR>", {noremap = true, silent = false, expr = true})
end

function adapter.search()
end

function adapter.backlink()
end

return adapter
