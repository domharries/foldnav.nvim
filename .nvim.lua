vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "foldnav.lua",
  callback = function() package.loaded.foldnav = nil end,
})
