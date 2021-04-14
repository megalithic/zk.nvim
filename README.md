# zk.nvim

**NOTE:** This plugin is presently _WIP_

A lightweight neovim, _lua-based_ wrapper around [`zk`](https://github.com/mickael-menu/zk).

The primary goals of this plugin are to provide handy maps, commands, and user-interface elements around the fantastic golang zettelkasten project, [`zk`](https://github.com/mickael-menu/zk).

For more information with how to fully use `zk`, please visit [`zk's docs`](https://github.com/mickael-menu/zk/tree/main/docs)

[`LSP` support within `zk`](https://github.com/mickael-menu/zk/pull/21) is new and still under development. It works quite well as-is, though. 😄
  * [nvim-lspconfig setup](https://github.com/mickael-menu/zk/pull/21#issuecomment-812773586)
  * [coc.nvim setup](https://github.com/mickael-menu/zk/pull/21#issue-608099016)


## Prerequisites

* `nvim-0.5.0` or higher
* For fzf support: [nvim-fzf](https://github.com/vijaymarupudi/nvim-fzf)
* For telescope.nvim support: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)


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
  default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "",
  fuzzy_finder = "fzf", -- or "telescope"
  link_format = "markdown" -- or "wikilink"
})
```


## Usage

For all usages of this plugin, the parlance of `notebook` is common place, and refers to a sub-directory within your root `ZK_NOTEBOOK_DIR`; or more specifically, a `notebook` is any directory that contains a `.zk` directory (think of it like a `.git`-controlled directory). 
These `notebooks` also relate to your [`groups`](https://github.com/mickael-menu/zk/blob/main/docs/config-group.md) setup within your `config.toml`.

#### Install [`zk`](https://github.com/mickael-menu/zk)

Install the [`zk`](https://github.com/mickael-menu/zk) binary (as long as `go` is installed in your system's `PATH`).

```vim
:ZkInstall
```

#### Create a new note

```viml
:lua require('zk.command').new({ title = "my note title" })
```

_Default arguments:_

```lua
{
  title = "",
  notebook = "",
  content = "",
  action = "vnew",
  start_insert_mode = true
}
```

#### Search/filtering of notes

`zk` offers such a wealth of power with searching, filtering and more for your
notes, notebooks, etc. Supports interacting with `fzf`, via flexible and fast
lua-based API, `nvim-fzf`. 

_Future support for `telescope.nvim` integration, coming soon._

```vim
:lua require('zk.command').search({ query = "hiring NOT onboarding" })
```

_Default arguments:_

```lua
{
  query = "",
  notebook = "",
  tags = "",
}
```

#### Generate a new note and inline link

Quickly change the word under cursor (or visually selected) to markdown or
wikilink syntax:

```viml
:lua require('zk.command').create_note_link({ title = "my note title", notebook = "wiki", action = "e" })
```

_Default arguments:_

```lua
{
  title = "",
  notebook = "",
  action = "vnew",
  open_note_on_creation = true
}
```

### Credit

- Mickael Menu (https://github.com/mickael-menu/zk)
- Evan Travers (http://evantravers.com/articles/tags/zettelkasten/)
- Zettelkasten Introduction (https://zettelkasten.de/introduction/#why-are-we-so-interested-in-luhmann-s-zettelkasten)
