local M = {}

---@class foldnav.Config
---@field highlight foldnav.HighlightConfig

---@class foldnav.HighlightConfig
---@field enabled boolean
---@field mode "opposite" | "fold"
---@field duration_ms integer

---@type foldnav.Config
local default_config = {
  highlight = {
    enabled = false,
    mode = "opposite",
    duration_ms = 300,
  },
}

---@type foldnav.Config | nil
vim.g.foldnav = vim.g.foldnav

local function load_config()
  return vim.tbl_deep_extend("force", default_config, vim.g.foldnav or {})
end

local function hidden_norm(cmd)
  vim.cmd("noautocmd keepjumps norm! " .. cmd)
end

local highlight_id

local function highlight(start_line, end_line, duration)
  local lines = {}
  for i = start_line, end_line do lines[#lines + 1] = i end

  if highlight_id then
    vim.fn.matchdelete(highlight_id)
  end
  highlight_id = vim.fn.matchaddpos("StatusLine", lines)

  vim.defer_fn(function()
    if highlight_id then
      vim.fn.matchdelete(highlight_id)
      highlight_id = nil
    end
  end, duration)
end

local function nav(fold_loc, line_fn)
  local saved_view = vim.fn.winsaveview()
  local saved_pos = vim.fn.getcurpos()

  line_fn()
  local lnum = vim.fn.line "."

  local fold_start, fold_end
  if fold_loc == "start" then
    fold_start = lnum
    hidden_norm "]z"
    fold_end = vim.fn.line "."
  else
    fold_end = lnum
    hidden_norm "[z"
    fold_start = vim.fn.line "."
  end

  vim.fn.setpos(".", saved_pos)
  vim.fn.winrestview(saved_view)

  if saved_pos[2] == lnum then return end -- didn't move

  vim.cmd(tostring(lnum))                 -- move to line
  vim.cmd "norm! m'"                      -- update jumplist

  local config = load_config()

  if config.highlight.enabled then
    if config.highlight.mode == "fold" then
      highlight(fold_start, fold_end, config.highlight.duration_ms)
    elseif config.highlight.mode == "opposite" then
      if fold_loc == "start" then
        highlight(fold_end, fold_end, config.highlight.duration_ms)
      else
        highlight(fold_start, fold_start, config.highlight.duration_ms)
      end
    end
  end
end

function M.to_start()
  nav("start", function() hidden_norm "[z" end)
end

function M.to_end()
  nav("end", function() hidden_norm "]z" end)
end

function M.to_next()
  nav("start", function() hidden_norm "zj" end)
end

function M.to_prev_end()
  nav("end", function() hidden_norm "zk" end)
end

function M.to_prev_start()
  nav("start", function()
    local init_line = vim.fn.line "."

    -- Detect consecutive sibling folds
    hidden_norm "zk"
    local prev = vim.fn.line "."

    local closed_fold_start = vim.fn.foldclosed(init_line)
    if closed_fold_start ~= -1 then
      init_line = closed_fold_start
    end

    local lastLevel = -1
    for i = init_line - 1, 1, -1 do
      local level = vim.fn.foldlevel(i)
      if level < lastLevel or (level == lastLevel and i == prev) then
        vim.fn.cursor(i + 1)
        return
      end
      lastLevel = level
    end
    if vim.fn.foldlevel(1) > 0 then
      vim.fn.cursor(1)
    end
  end)
end

return M
