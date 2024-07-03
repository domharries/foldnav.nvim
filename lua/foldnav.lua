local M = {}

local function change_line_keep_col(lineFn)
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

function M.to_start()
  change_line_keep_col(function() vim.cmd "keepjumps norm! [z" end)
end

function M.to_end()
  change_line_keep_col(function() vim.cmd "keepjumps norm! ]z" end)
end

function M.to_next()
  change_line_keep_col(function() vim.cmd "keepjumps norm! zj" end)
end

function M.to_prev_end()
  change_line_keep_col(function() vim.cmd "keepjumps norm! zk" end)
end

function M.to_prev_start()
  change_line_keep_col(function()
    -- Detect consecutive sibling folds
    local savedView = vim.fn.winsaveview()
    local savedPos = vim.fn.getcurpos()
    vim.cmd "keepjumps norm! zk"
    local prev = vim.fn.line "."
    vim.fn.setpos(".", savedPos)
    vim.fn.winrestview(savedView)

    local visibleLine
    ---@diagnostic disable-next-line: param-type-mismatch
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
end

return M
