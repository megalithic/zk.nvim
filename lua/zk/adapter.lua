-- The interface between our plugin and zk

local adapter = {}

function adapter.new()
  zk_util.command {
    "ZkNew",
    function()
    end
  }
  vim.api.nvim_set_keymap("n", "<leader>zn", "<cmd>ZkNew<CR>", {noremap = true, silent = false, expr = false})
end

function adapter.search()
end

function adapter.backlink()
end

return adapter
