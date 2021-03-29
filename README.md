# zk.nvim

**NOTE:** This plugin is presently _WIP_

A lightweight neovim, _lua-based_ wrapper around [`zk`](https://github.com/mickael-menu/zk).

The primary goals of this plugin are to provide handy maps, commands, and
user-interface elements around the fantastic golang zettelkasten project,
[`zk`](https://github.com/mickael-menu/zk).


## Prerequisites

* `neovim-0.5.0` or higher.

## Install

#### paq-nvim

`paq { "megalithic/zk.nvim" }`

#### packer.nvim

`use { "megalithic/zk.nvim" }`

#### vim-plug

`Plug "megalithic/zk.nvim"`


## Configuration


```lua
-- with default config options:

require("zk").setup({
  debug = false,
  log = true,
  enable_default_keymaps = true,
  root_target = ".zk",
  default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or ""
})
```


## Usage


#### Install [`zk`](https://github.com/mickael-menu/zk)

Install the [`zk`](https://github.com/mickael-menu/zk) binary (as long as `go` is installed in your system's `PATH`).

```viml
:ZkInstall
```

#### Create a new note

Create a new note, with an optional title string.

```viml
:lua require('zk.command').new({ title = "my note title" })
```

Available _new note_ arguments:

```lua
{
  title = "",
  content = "",
  action = "vnew",
  notebook = "",
  start_insert_mode = true
}
```

### Credit

- Mickael Menu (https://github.com/mickael-menu/zk)
- Evan Travers (http://evantravers.com/articles/tags/zettelkasten/)
- ZettelKasten Introduction (https://zettelkasten.de/introduction/#why-are-we-so-interested-in-luhmann-s-zettelkasten)
