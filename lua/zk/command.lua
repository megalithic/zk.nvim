-- The interface to provide the available commands via lua to nvim

local adapter = require("zk.adapter")

local M = {}

local zk_repo_path = "github.com/mickael-menu/zk"

local function call_go_cmd()
  local cmd = {"go", "get", "-u", zk_repo_path}
  vim.fn.jobstart(
    cmd,
    {
      on_exit = function(_, d, _)
        if d == 0 then
          vim.api.nvim_out_write("[zk.nvim] latest zk installed")
          return
        end
        vim.api.nvim_err_writeln("[zk.nvim] failed to install zk")
      end
    }
  )
end

function M.install_zk()
  if not vim.fn.executable("go") == 0 then
    vim.api.nvim_err_writeln("[zk.nvim] golang not installed. It must be installed before continuing.")
  end

  if vim.fn.executable("zk") == 1 then
    local answer = vim.fn.input("[zk.nvim] latest zk already installed, do you want update? Y/n -> ")
    answer = string.lower(answer)
    while answer ~= "y" and answer ~= "n" do
      answer = vim.fn.input("[zk.nvim] please answer Y or n -> ")
      answer = string.lower(answer)
    end

    if answer == "n" then
      vim.api.nvim_out_write("\n")
      vim.cmd([[redraw]])

      return
    end

    vim.api.nvim_out_write("[zk.nvim] updating zk..\n")
  else
    print("[zk.nvim] installing zk..")
  end

  call_go_cmd()
end

function M.new(...)
  return adapter.new(...)
end

return M
