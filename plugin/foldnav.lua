local function changeLineKeepCol(lineFn)
  -- curswant is a virtual col
  local curswant = vim.fn.getcurpos()[5]

  local lnum = lineFn() or vim.fn.line "."

  -- will round down to $ if beyond end of line
  local col = vim.fn.virtcol2col(0, lnum, curswant)
  -- for virtualedit always pad out to curswant
  local off = curswant - vim.fn.virtcol { lnum, col, 0 }
  vim.fn.cursor { lnum, col, off, curswant }
  vim.cmd "norm! m'" -- update jumplist
end

vim.keymap.set("", "<Plug>(foldnav-start)", function()
  changeLineKeepCol(function() vim.cmd "keepjumps norm! [z" end)
end)

vim.keymap.set("", "<Plug>(foldnav-end)", function()
  changeLineKeepCol(function() vim.cmd "keepjumps norm! ]z" end)
end)

vim.keymap.set("", "<Plug>(foldnav-next)", function()
  changeLineKeepCol(function() vim.cmd "keepjumps norm! zj" end)
end)

vim.keymap.set("", "<Plug>(foldnav-previous-end)", function()
  changeLineKeepCol(function() vim.cmd "keepjumps norm! zk" end)
end)

vim.keymap.set("", "<Plug>(foldnav-previous-start)", function()
  changeLineKeepCol(function()
    -- Detect consecutive sibling folds
    local savedView = vim.fn.winsaveview()
    local savedPos = vim.fn.getcurpos()
    vim.cmd "keepjumps norm! zk"
    local prev = vim.fn.line "."
    vim.fn.setpos(".", savedPos)
    vim.fn.winrestview(savedView)

    local visibleLine
    local closedFoldStart = vim.fn.foldclosed "."
    if closedFoldStart == -1 then
      visibleLine = vim.fn.line "."
    else
      visibleLine = closedFoldStart
    end

    local lastLevel = -1
    for i = visibleLine - 1, 1, -1 do
      local level = vim.fn.foldlevel(i)
      if level < lastLevel or (level == lastLevel and i == prev) then
        return i + 1
      end
      lastLevel = level
    end
    if vim.fn.foldlevel(1) > 0 then return 1 end
  end)
end)
