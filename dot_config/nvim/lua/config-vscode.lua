-- Use 2 spaces for indentation.
local indent_width = 2
vim.opt.tabstop = indent_width -- indenting with tab
vim.opt.softtabstop = indent_width
vim.opt.shiftwidth = indent_width -- indenting with >
vim.opt.expandtab = true -- use spaces, not tab characters

-- Use 80 characters as the maximum line length.
local text_width = 80
vim.opt.textwidth = text_width
vim.opt.colorcolumn = { text_width + 1 }

-- Yank/paste from/to clipboard.
vim.opt.clipboard:append({ "unnamedplus" })

-- Align wrapped lines with the indentation for that line.
vim.opt.breakindent = true
