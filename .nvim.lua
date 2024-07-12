vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "foldnav.lua",
  callback = function() package.loaded.foldnav = nil end,
})

vim.opt.makeprg = "./tests.lua"

vim.fn.writefile({ "exec ./tests.lua" }, ".git/hooks/pre-commit")
vim.fn.setfperm(".git/hooks/pre-commit", "rwxr-xr-x")
