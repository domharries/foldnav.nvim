# foldnav.nvim

Wrapper around vim's [fold navigation
commands](https://neovim.io/doc/user/fold.html#%5Bz) that:

  - maintains the cursor column
  - adds a `goto_prev_start()` mapping to move to the most recent start of
    a fold
  - can highlight the fold during navigation
  - is optimised for speedy navigation with a modifier and `hjkl`

_demo video_

The demo was recorded with the lazy.nvim example config shown below.

## Setup

### Requirements

Foldnav needs a buffer with folds. A good way to achieve this is to use
treesitter. This can be enabled with the following Lua code:

```lua
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99 -- load buffers with folds open
```

See [`:help
treesitter-parsers`](https://neovim.io/doc/user/treesitter.html#_parser-files)
to enable treesitter for more filetypes.

To test if folding works, run `:set foldcolumn=auto:9`. This should show
all the folds for your current file in the left margin (see video above).

### Plugin Installation

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
them for visual and even operator pending mode by changing the first
argument to `{"n", "x", "o"}`. See [`:help
map-modes`](https://neovim.io/doc/user/map.html#_1.3-mapping-and-modes)
for more information.

**Hint:** If you want to configure the plugin to go to the start or end
of the line when navigating, you can call `^` or `$` at the end of the
mapping, e.g.

```lua
vim.keymap.set("n", "<C-h>", function()
  require("foldnav").goto_start()
  vim.cmd.normal("^")
end)
```

## Actions

The movements that this plugin provides are shown below, with their
equivalent vim commands:

| Function            | vim    | Target                                    |
| ------------------- | ------ | ----------------------------------------- |
| `goto_start()`      | `[z`   | Start of the enclosing fold               |
| `goto_next()`       | `zj`   | Start of next fold                        |
| `goto_prev_start()` | _None_ | The most recent place that a fold started |
| `goto_prev_end()`   | `zk`   | End of the previous fold                  |
| `goto_end()`        | `]z`   | End of the enclosing fold                 |

### Choosing between `goto_prev_start()` and `goto_prev_end()`

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
  - Can use <kbd>Mod</kbd>+<kbd>jljljl</kbd> and
    <kbd>Mod</kbd>+<kbd>khkhkh</kbd> to go up and down at a constant
    level of nesting (useful for JSON)
  - To reverse a <kbd>Mod</kbd>+<kbd>j</kbd> navigation, you can use
    <kbd>Ctrl</kbd>+<kbd>o</kbd> to navigate backwards in the jumplist.

Of course it is perfectly possible to map both functions with different
keys.

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

**Note:** directly setting individual values does [not work in
Lua](https://neovim.io/doc/user/lua.html#lua-vim-variables).

The highlight group used for the flash is `FoldnavFlash`. By default it
links to the `CursorLine` highlight group but can be customised using
`:highlight` or `vim.api.nvim_set_hl()`.

## Motivation

I've never been happy with vertical motion in vim. Typing line numbers
or counts for `j`/`k` actions has always seemed clunky.

Now that Neovim has treesitter support, there is a new level of semantic
data that can be used for navigation. However, choosing appropriate
treesitter queries is not so easy. The
[nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
project defines a lot of useful queries, and `@block.outer` is a good
candidate for vertical navigation. But it doesn't allow navigating data
structure literals or configuration languages like JSON.

Happily the requirements I have for vertical navigation are well aligned
with the requirements for deciding where to put fold markers. Neovim now
uses treesitter for deciding where code should fold, and there is a
high-quality collection of fold definitions for a large range of
programming languages.

So this plugin piggybacks on folds, either defined with treesitter or
whichever other method is configured (see [`:help
'foldmethod'`](https://neovim.io/doc/user/options.html#'foldmethod')).

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
