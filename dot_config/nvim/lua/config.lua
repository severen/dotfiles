-- Preamble {{{

-- Alias some interfaces for brevity.
local g = vim.g
local opt = vim.opt
local opt_global = vim.opt_global
local opt_local = vim.opt_local
local cmd = vim.cmd
local api = vim.api

-- Add a more convenient way of creating key bindings.
local function map(mode, lhs, rhs, options)
  local base_options = { noremap = true, silent = true }
  vim.keymap.set(
    mode,
    lhs,
    rhs,
    not options and base_options
      or vim.tbl_extend("force", base_options, options)
  )
end

-- Bootstrap the plugin manager.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set the global leader to SPC and the local leader to SPC m.
g.mapleader = " " -- NOTE: Must be set before specifying plugins.
g.maplocalleader = " m"

-- }}}

-- {{{ Plugins

local lazy_config = {
  performance = {
    rtp = {
      -- These bundled plugins are either not used by me or superseded by
      -- another plugin.
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
}

require("lazy").setup({
  -- {{{ Libraries
  { "nvim-lua/plenary.nvim", name = "plenary" },
  -- }}}

  -- {{{ Visuals
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    name = "lualine",
    event = "VeryLazy",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
      },
    },
  },
  { "stevearc/dressing.nvim", name = "dressing", event = "VeryLazy" },
  -- }}}

  -- {{{ Interface
  { "folke/which-key.nvim", name = "which-key", config = true },
  { "Lokaltog/neoranger", cmd = { "Ranger", "RangerCurrentFile" } },
  { "simnalamburt/vim-mundo", cmd = { "MundoShow", "MundoToggle" } },
  {
    "lewis6991/gitsigns.nvim",
    name = "gitsigns",
    event = "VeryLazy",
    config = true,
  },
  {
    "folke/todo-comments.nvim",
    name = "todo-comments",
    event = "VeryLazy",
    config = true,
  },
  {
    "NvChad/nvim-colorizer.lua",
    name = "colorizer",
    event = "VeryLazy",
    opts = { filetypes = { "html", "css", "javascript", "typescript" } },
  },
  { "rcarriga/nvim-notify", name = "notify", event = "VeryLazy" },
  { "folke/noice.nvim", event = "VeryLazy" },
  -- }}}

  -- {{{ Editing
  {
    "tmsvg/pear-tree",
    event = "InsertEnter",
    init = function()
      g.pear_tree_smart_openers = 1
      g.pear_tree_smart_closers = 1
      g.pear_tree_smart_backspace = 1
    end,
  },
  { "echasnovski/mini.ai", config = true },
  { "echasnovski/mini.comment", config = true },
  { "kylechui/nvim-surround", config = true },
  {
    "andymass/vim-matchup",
    config = function()
      g.matchup_matchparen_offscreen = { method = "status_manual" }
    end,
  },
  {
    "ggandor/leap.nvim",
    name = "leap",
    config = function()
      require("leap").add_default_mappings()
    end,
  },
  { "ggandor/leap-spooky.nvim", name = "leap-spooky", config = true },
  { "ggandor/flit.nvim", name = "flit", config = true },
  -- }}}

  -- {{{ Completion and Diagnostics
  {
    "hrsh7th/nvim-cmp",
    name = "cmp",
    -- load cmp on InsertEnter
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
    },
    config = function()
      -- TODO: Setup completion.
    end,
  },

  -- {{{ Language Support
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash",
          "bibtex",
          "c",
          "c_sharp",
          "cmake",
          "cpp",
          "css",
          "dockerfile",
          "eex",
          "elixir",
          "erlang",
          "fish",
          "glsl",
          "go",
          "haskell",
          "heex",
          "html",
          "java",
          "javascript",
          "jsdoc",
          "json",
          "just",
          "kotlin",
          "lua",
          "markdown",
          "markdown_inline",
          "meson",
          "ninja",
          "nix",
          "ocaml",
          "ocaml_interface",
          "perl",
          "php",
          "prolog",
          "python",
          "qmljs",
          "query",
          "regex",
          "ruby",
          "rust",
          "sql",
          "svelte",
          "toml",
          "typescript",
          "vim",
          "vimdoc",
          "wgsl",
          "yaml",
          "zig"
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        -- TODO: Revisit this when Tree Sitter powered indentation is less
        -- buggy. I disabled this because I ran into issues with indentation in
        -- Rust code.
        indent = { enable = false },
        matchup = { enable = true },
        playground = { enable = true },
      })
    end,
  },
  { "nvim-treesitter/playground", cmd = "TSPlaygroundToggle" },
  { "Shirk/vim-gas" },
  { "lervag/vimtex", ft = "tex" },
  {
    "nvim-neorg/neorg",
    ft = "norg",
    config = function()
      require("neorg").setup({
        load = {
          ["core.defaults"] = {},
          ["core.norg.concealer"] = {},
          ["core.norg.completion"] = {
            config = { engine = "nvim-cmp" },
          },
          ["core.integrations.nvim-cmp"] = {},
        },
      })
    end,
  },
  -- }}}
}, lazy_config)

-- }}}

-- Visuals {{{

-- Use 24-bit colour like it's 1995!
opt.termguicolors = true

-- Load my default colorscheme of choice.
cmd.colorscheme("catppuccin-mocha")

-- The current mode is already displayed in the status line (by Lualine).
vim.opt.showmode = false

-- }}}

-- Interface {{{

map("n", "<leader><leader>", ":", { desc = "Run Ex command" })
map("n", "<leader>q", ":qa<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qa<CR>", { desc = "Force quit" })

-- Disable arrow keys in normal/visual mode so that I can break the habit.
for _, direction in ipairs({ "up", "down", "left", "right" }) do
  map("", "<" .. direction .. ">", "<nop>")
end

-- Always display the sign column to avoid unwarranted jumps.
opt.signcolumn = "yes"

-- Do not wrap lines longer than the window width.
opt.wrap = false

-- Align wrapped lines with the indentation for that line.
opt.breakindent = true

-- Enable flash on yank.
api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Improve the behaviour of search.
opt.ignorecase = true
opt.smartcase = true
opt.gdefault = true

-- Start scrolling 4 lines before the edge of the window.
opt.scrolloff = 4
opt.sidescrolloff = 4

-- Enable relative line numbers.
opt.number = true
opt.relativenumber = true

-- More specifically, use relative line numbers in normal mode and absolute line
-- numbers in insert mode.
api.nvim_create_augroup("LineNumbers", {})
api.nvim_create_autocmd(
  { "BufEnter", "FocusGained", "InsertLeave", "WinEnter" },
  {
    group = "LineNumbers",
    callback = function()
      if opt.number:get() then
        opt.relativenumber = true
      end
    end,
  }
)
api.nvim_create_autocmd(
  { "BufLeave", "FocusLost", "InsertEnter", "WinLeave" },
  {
    group = "LineNumbers",
    callback = function()
      if opt.number:get() then
        opt.relativenumber = false
      end
    end,
  }
)

api.nvim_create_autocmd("TermOpen", {
  callback = function()
    -- Also, don't display line numbers in the integrated terminal.
    opt_local.number = false
    opt_local.relativenumber = false

    -- Default to insert mode in the integrated terminal.
    cmd.startinsert()
  end,
})

-- Highlight the line the cursor is on in the currently active buffer.
local cursor_line_group = api.nvim_create_augroup("CursorLine", {})
api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  group = cursor_line_group,
  callback = function()
    opt_local.cursorline = true
  end,
})
api.nvim_create_autocmd({ "WinLeave" }, {
  group = cursor_line_group,
  callback = function()
    opt_local.cursorline = false
  end,
})

-- Jump to the last known cursor position when opening a file, so long as the
-- position is still valid and we are not editing a commit message (it's likely
-- a different one than last time).
api.nvim_create_autocmd("BufReadPost", {
  group = api.nvim_create_augroup("RestorePosition", { clear = true }),
  callback = function(args)
    local is_valid_line =
      vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) <= vim.fn.line("$")
    local is_not_commit = vim.b[args.buf].filetype ~= "commit"

    if is_valid_line and is_not_commit then
      cmd([[normal! g`"]])
    end
  end,
})

-- Automatically create parent directories when saving a file.
api.nvim_create_autocmd("BufWritePre", {
  group = api.nvim_create_augroup("auto_create_dir", { clear = true }),
  callback = function(event)
    local file = vim.loop.fs_realpath(event.match) or event.match

    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    local backup = vim.fn.fnamemodify(file, ":p:~:h")
    backup = backup:gsub("[/\\]", "%%")
    opt_global.backupext = backup
  end,
})

-- }}}

-- {{{ Editing

-- Use 2 spaces for indentation.
local indent_width = 2
opt.tabstop = indent_width -- indenting with tab
opt.softtabstop = indent_width
opt.shiftwidth = indent_width -- indenting with >
opt.expandtab = true -- use spaces, not tab characters

-- Use 80 characters as the maximum line length.
local text_width = 80
opt.textwidth = text_width
opt.colorcolumn = { text_width + 1 }

-- Stop the Rust ftplugin from fucking with the above.
g.rust_recommended_style = false

-- Delete a level of indentation with Shift+Tab.
map("i", "<S-Tab>", "<C-d>")

-- Map Ctrl+Backspace to delete backwards by words.
map("i", "<C-BS>", "<C-w>")

-- Display invisible characters.
opt.list = true
opt.listchars = {
  tab = "•·",
  trail = "·",
  extends = "❯",
  precedes = "❮",
  nbsp = "×",
}

-- Persist undo history.
opt.undofile = true

-- TODO: Replace with a ctrl+y binding for yank to clipboard.
opt.clipboard:append({ "unnamedplus" })

-- Associate the GLSL filetype with the typical file extensions used for
-- shaders.
api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.vert", "*.frag", "*.tesc", "*.geom", "*.comp" },
  callback = function()
    opt_local.filetype = "glsl"
  end,
})

-- }}}

-- {{{ Completion and Diagnostics

-- Use British English and New Zealand English dictionaries for spell checking.
opt.spelllang = { "en_gb", "en_nz" }

-- Enable spell checking.
opt.spell = true

-- }}}

-- vim: set et foldlevel=0 foldmethod=marker:
