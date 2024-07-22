# foldnav.nvim

## Overview

Vim's vertical navigation commands can be limiting, and users often rely
on methods like manual line counting (`5j`) to reach their desired
location. It would be useful to have a way to navigate based on the
semantic structure of a buffer, with meaningful points of reference.

Fortunately, this problem is already solved in another area: code
folding. Neovim's Treesitter support provides a high-quality repository
of queries that define folds based on programming language semantics,
which can also power vertical navigation.

Vim provides some built in commands for navigating folds:
[\[z](https://neovim.io/doc/user/fold.html#%5Bz),
[z\]](https://neovim.io/doc/user/fold.html#%5Dz),
[zj](https://neovim.io/doc/user/fold.html#zj) and
[zk](https://neovim.io/doc/user/fold.html#zk). However, these have some
shortcomings:

  - The `zk` keybinding moves to the end of the previous fold rather
    than the most recent start of a fold, which is unintuitive
  - The cursor is moved to the very start of the line (unlike other
    vertical navigation commands)
  - The keybindings are awkward which makes it difficult to repeat
    motions or compose multiple motions together
  - There is no visual feedback of the fold structure while navigating

This plugins fixes these shortcomings.

### Demo video

https://github.com/user-attachments/assets/b2d0a139-8c10-4d58-9e28-6291d45ff922

The demo was recorded with the lazy.nvim example config shown below.

## Setup

### Requirements

Foldnav requires a buffer with folds to operate. To use treesitter for
folding, add the following Lua code to your config:

```lua
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99 -- load buffers with folds open
```

See
[treesitter-parsers](https://neovim.io/doc/user/treesitter.html#_parser-files)
to enable treesitter for more filetypes.

To test if folding works, run `:set foldcolumn=auto:9`. This shows all
the folds for your current file in the left margin (see video above).

### Plugin installation

Example using [lazy.nvim](https://github.com/folke/lazy.nvim) to
install, enable highlighting, and map the <kbd>Ctrl</kbd> modifier:

```lua
  {
    "domharries/foldnav.nvim",
    version = "*",
    config = function()
      vim.g.foldnav = {
        flash = {
          enabled = true,
        },
      }
    end,
    keys = {
      { "<C-h>", function() require("foldnav").goto_start() end },
      { "<C-j>", function() require("foldnav").goto_next() end },
      { "<C-k>", function() require("foldnav").goto_prev_start() end },
      -- { "<C-k>", function() require("foldnav").goto_prev_end() end },
      { "<C-l>", function() require("foldnav").goto_end() end },
    },
  },
```

Example using `vim.keymap.set` to map the <kbd>Alt</kbd> modifier:

```lua
vim.keymap.set("n", "<M-h>", function() require("foldnav").goto_start() end)
vim.keymap.set("n", "<M-j>", function() require("foldnav").goto_next() end)
vim.keymap.set("n", "<M-k>", function() require("foldnav").goto_prev_start() end)
-- vim.keymap.set("n", "<M-k>", function() require("foldnav").goto_prev_end() end)
vim.keymap.set("n", "<M-l>", function() require("foldnav").goto_end() end)
```

These mappings are defined for normal mode, but you could also define
them for visual and operator pending mode by changing the first argument
to `{"n", "x", "o"}`. See
[:map-modes](https://neovim.io/doc/user/map.html#_1.3-mapping-and-modes)
for more information.

## Motions

The movements that this plugin provides are shown below, with their
equivalent vim commands:

| Function            | vim    | Target                                    |
| ------------------- | ------ | ----------------------------------------- |
| `goto_start()`      | `[z`   | Start of the enclosing fold               |
| `goto_next()`       | `zj`   | Start of next fold                        |
| `goto_prev_start()` | _None_ | The most recent place that a fold started |
| `goto_prev_end()`   | `zk`   | End of the previous fold                  |
| `goto_end()`        | `]z`   | End of the enclosing fold                 |

### Mapping mod+k

Fold navigation maps quite nicely onto the standard vim `hjkl` movement
keys, but there are two options for mapping <kbd>Mod</kbd>+<kbd>k</kbd>.

Pros for `goto_prev_start()`:

  - More intuitive for most people
  - <kbd>Mod</kbd>+<kbd>k</kbd> always does the reverse of
    <kbd>Mod</kbd>+<kbd>j</kbd>

Pros for `goto_prev_end()`:

  - Matches the built in vim movements - it's easy to map a few keys on
    vanilla vim to get functionality that is mostly equivalent. See
    [Alternatives](#alternatives) below.
  - Can use <kbd>Mod</kbd>+<kbd>ljljlj</kbd> and
    <kbd>Mod</kbd>+<kbd>khkhkh</kbd> to go up and down at a constant
    level of nesting (useful for JSON)
  - To reverse a <kbd>Mod</kbd>+<kbd>j</kbd> navigation, you can use
    <kbd>Ctrl</kbd>+<kbd>o</kbd> to navigate backwards in the jumplist.

Of course it is perfectly possible to map both functions with different
keys.

### Cursor column

To configure the plugin to go to the start or end of the line when
navigating, you can call `^` or `$` at the end of the mapping, e.g.

```lua
vim.keymap.set("n", "<C-h>", function()
  require("foldnav").goto_start()
  vim.cmd.normal("^")
end)
```

### Constant fold level

The bindings shown so far will navigate across multiple fold levels. The
following mappings will navigate to the next and previous fold on the
same level where possible:

```lua
vim.keymap.set("n", "<M-n>", function()
  local foldnav = require("foldnav")
  foldnav.goto_end()
  foldnav.goto_next()
end)

vim.keymap.set("n", "<M-p>", function()
  local foldnav = require("foldnav")
  foldnav.goto_prev_end()
  foldnav.goto_start()
end)
```

## Configuration

Foldnav is configured with a global variable `vim.g.foldnav`. There is
no need to set this variable if you want to use the defaults. These are
all the settings at their default values:

```lua
vim.g.foldnav = {
  flash = {
    enabled = false,
    mode = "fold", -- or "opposite"
    duration_ms = 300
  }
}
```

| Parameter         | Default  | Description                                               |
| ----------------- | -------- | --------------------------------------------------------- |
| flash.enabled     | `false`  | Enable highlighting fold after navigation                 |
| flash.mode        | `"fold"` | `"fold"` = entire fold, `"opposite"` = other edge of fold |
| flash.duration_ms | `300`    | Highlight duration in milliseconds                        |

Individual parameters can be changed for the current session by using
`:let` on the command line:

```vim
:let g:foldnav.flash.enabled = v:true
:let g:foldnav.flash.mode = "opposite"
```

Note: directly setting individual values does not work in Lua, see
[lua-vim-variables](https://neovim.io/doc/user/lua.html#lua-vim-variables).

The highlight group used for the flash is `FoldnavFlash`. By default it
links to the `CursorLine` highlight group but can be customised using
[:highlight](https://neovim.io/doc/user/syntax.html#_13.-highlight-command)
or [nvim_set_hl()](https://neovim.io/doc/user/api.html#nvim_set_hl()).

## Alternatives

Excluding the `goto_prev_start()` function, most of what this plugin
does can be approximated with the following Lua code (<kbd>Ctrl</kbd>
modifier shown):

```lua
vim.keymap.set("", "<C-h>", "[zjk")
vim.keymap.set("", "<C-j>", "zjkj")
vim.keymap.set("", "<C-k>", "zkjk")
vim.keymap.set("", "<C-l>", "]zkj")
```

Or the following vimscript:

```vim
noremap <C-h> [zjk
noremap <C-j> zjkj
noremap <C-k> zkjk
noremap <C-l> ]zkj
```

The `jk` and `kj` suffixes put the cursor in the correct column after
navigation.
