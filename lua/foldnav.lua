local M = {}

---@class foldnav.Config
---@field flash foldnav.FlashConfig

---@class foldnav.FlashConfig
---@field enabled boolean
---@field mode "opposite" | "fold"
---@field duration_ms integer

---@type foldnav.Config
local default_config = {
  flash = {
    enabled = false,
    mode = "fold",
    duration_ms = 300,
  },
}

---@type foldnav.Config | nil
vim.g.foldnav = vim.g.foldnav

---@return foldnav.Config
local function load_config()
  return vim.tbl_deep_extend("force", default_config, vim.g.foldnav or {})
end

local function hidden_norm(cmd)
  vim.cmd("noautocmd keepjumps norm! " .. cmd)
end

local mark_ns = vim.api.nvim_create_namespace "foldnav"
local mark_id = 1
local mark_timer

vim.api.nvim_set_hl(0, "FoldnavFlash", {
  default = true, link = "CursorLine",
})

local function flash_range(start_line, end_line, duration)
  -- cancel previous timer
  if mark_timer and not mark_timer:is_closing() then
    mark_timer:close()
  end

  vim.api.nvim_buf_set_extmark(0, mark_ns, start_line - 1, 0, {
    id = mark_id,
    end_row = end_line,
    hl_group = "FoldnavFlash",
    hl_eol = true,
  })

  mark_timer = vim.defer_fn(function()
    vim.api.nvim_buf_del_extmark(0, mark_ns, mark_id)
  end, duration)
end

local function nav(fold_loc, line_fn)
  local saved_view = vim.fn.winsaveview()
  local saved_pos = vim.fn.getcurpos()

  for _ = 1, vim.v.count1 do
    line_fn()
  end

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

  if config.flash.enabled then
    if config.flash.mode == "fold" then
      flash_range(fold_start, fold_end, config.flash.duration_ms)
    elseif config.flash.mode == "opposite" then
      if fold_loc == "start" then
        flash_range(fold_end, fold_end, config.flash.duration_ms)
      else
        flash_range(fold_start, fold_start, config.flash.duration_ms)
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
        vim.cmd(tostring(i + 1))
        return
      end
      lastLevel = level
    end
    if vim.fn.foldlevel(1) > 0 then
      vim.cmd(tostring(1))
    end
  end)
end

return M
