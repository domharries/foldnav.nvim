#!/usr/bin/env -S nvim --headless -u NONE -l
vim.opt.runtimepath:append "."

local cmd = vim.cmd
local fn = vim.fn
local foldnav = require "foldnav"

local function assert_eq(x, y)
  if x ~= y then error(x .. " ~= " .. y, 2) end
end

local fixture = [[
01 {{{1
02 }}}1
03
04 {{{1
05   {{{2
06
07   }}}2
08   {{{2
09
10 }}}1
11
12
]]

local cases = {
  function() -- basic navigation
    foldnav.goto_next()
    assert_eq(fn.line("."), 4)
    foldnav.goto_prev_start()
    assert_eq(fn.line("."), 1)
  end,
  function() -- consecutive folds
    fn.cursor(10, 1)
    foldnav.goto_prev_start()
    assert_eq(fn.line("."), 8)
    foldnav.goto_prev_start()
    assert_eq(fn.line("."), 5)
  end,
  function() -- off the edge of the buffer
    foldnav.goto_prev_start()
    assert_eq(fn.line("."), 1)
    fn.cursor(10, 1)
    foldnav.goto_next()
    assert_eq(fn.line("."), 10)
  end,
  function() -- up and previous hierarchy
    fn.cursor(5, 1)
    foldnav.goto_prev_start()
    assert_eq(fn.line("."), 4)
    foldnav.goto_prev_start()
    assert_eq(fn.line("."), 1)
  end,
  function() -- escape closed folds
    fn.cursor(4, 1)
    cmd.norm "zc"
    fn.cursor(12, 1)
    foldnav.goto_prev_start()
    foldnav.goto_prev_start()
    -- clear entire fold
    assert_eq(fn.line("."), 1)
  end,
  function() -- counts
    vim.keymap.set("n", "J", foldnav.goto_next)
    cmd.norm "3J"
    assert_eq(fn.line("."), 8)
    vim.keymap.del("n", "J")
  end,
}

vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(fixture, "\n"))
vim.opt.foldmethod = "marker"

local all_passed = true

for _, test in ipairs(cases) do
  fn.cursor(1, 1)
  cmd "%foldopen!"

  local pass, err = pcall(test)
  if not pass then
    print(err .. "\n")
    all_passed = false
  end
end

if all_passed then
  print "All tests passed!\n"
else
  os.exit(1)
end
