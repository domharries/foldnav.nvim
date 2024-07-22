vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "foldnav.lua",
  callback = function() package.loaded.foldnav = nil end,
})

vim.opt.makeprg = "./tests.lua"

vim.uv.fs_symlink("../../.githooks/pre-commit", ".git/hooks/pre-commit")
