-- Use 2 spaces for indentation.
local indent_width = 2
opt.tabstop = indent_width -- indenting with tab
opt.softtabstop = indent_width
opt.shiftwidth = indent_width -- indenting with >
opt.expandtab = true -- use spaces, not tab characters

-- Use 80 characters as the maximum line length.
local text_width = 80
opt.textwidth = text_width
opt.colorcolumn = {text_width + 1}

-- Yank/paste from/to clipboard.
opt.clipboard:append { "unnamedplus" }

-- Align wrapped lines with the indentation for that line.
opt.breakindent = true
