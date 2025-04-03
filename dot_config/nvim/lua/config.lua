-- Preamble ⦃

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
if not vim.uv.fs_stat(lazypath) then
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
vim.g.mapleader = " " -- NOTE: Must be set before specifying plugins.
vim.g.maplocalleader = " m"

-- ⦄

-- Plugins ⦃

local lazy_config = {
  performance = {
    rtp = {
      -- Prevent loading bundled plugins that are not required or superseded by
      -- other plugins.
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}

require("lazy").setup({
  -- Libraries ⦃
  { "nvim-lua/plenary.nvim", name = "plenary" },
  -- ⦄

  -- Visuals ⦃
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      show_end_of_buffer = true,
      dim_inactive = { enabled = true },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
        section_separators = { left = "", right = "" },
        -- Only display one 'global' status line rather than one per window.
        globalstatus = true,
      },
      sections = {
        lualine_a = {
          { "mode", separator = { left = "" }, right_padding = 2 },
        },
        lualine_b = { "filename", "branch" },
        lualine_c = { },
        lualine_x = {},
        lualine_y = {
          "filetype",
          {
            "fileformat",
            separator = { right = "" },
            padding = { left = 1, right = 0 },
          },
          "encoding",
          "progress",
        },
        lualine_z = {
          { "location", separator = { right = "" }, left_padding = 2 },
        },
      },
      inactive_sections = {
        lualine_a = { "filename" },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      },
      extensions = { "lazy", "mundo", "quickfix" },
    },
  },
  { "stevearc/dressing.nvim", name = "dressing", event = "VeryLazy" },
  -- ⦄

  -- Interface ⦃
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {},
  },
  {
    "folke/which-key.nvim",
    name = "which-key",
    config = true,
  },
  {
    "folke/snacks.nvim",
    dependencies = { "echasnovski/mini.nvim", version = false },
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = { enabled = true },
      explorer = { enabled = true },
      input = { enabled = true },
      picker = { enabled = true },
      session = { enabled = true },
      zen = { enabled = true },
    },
    keys = {
      {
        "<leader><leader>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>n",
        function()
          Snacks.picker.notifications()
        end,
        desc = "Notification History",
      },
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },

      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },

      {
        "<leader>z",
        function()
          Snacks.zen()
        end,
        desc = "Toggle Zen Mode",
      },
      {
        "<leader>N",
        desc = "Neovim News",
        function()
          Snacks.win({
            file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            width = 0.9,
            height = 0.8,
            wo = {
              spell = false,
              wrap = false,
              signcolumn = "yes",
              statuscolumn = " ",
              conceallevel = 3,
            },
          })
        end,
      },
    },
  },
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim", lazy = false },
    opts = {
      open_for_directories = true,
    },
    init = function()
      -- Fake loading the netrw plugin so that the `open_for_directories` option
      -- functions.
      vim.g.loaded_netrwPlugin = 1
    end,
    keys = {
      {
        "<leader>fb",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Browse files",
      },
    },
  },
  { "simnalamburt/vim-mundo", cmd = { "MundoShow", "MundoToggle" } },
  {
    "lewis6991/gitsigns.nvim",
    name = "gitsigns",
    event = "VeryLazy",
    config = true,
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "folke/snacks.nvim" },
    event = { "BufNewFile", "BufReadPost" },
    opts = {},
    keys = {
      {
        "<leader>st",
        function()
          Snacks.picker.todo_comments()
        end,
        desc = "Todo",
      },
      {
        "<leader>sT",
        function()
          Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
        end,
        desc = "Todo/Fix/Fixme",
      },
    },
  },
  {
    "NvChad/nvim-colorizer.lua",
    name = "colorizer",
    event = "VeryLazy",
    opts = { filetypes = { "html", "css", "javascript", "typescript" } },
  },
  { "rcarriga/nvim-notify", name = "notify", event = "VeryLazy" },
  { "folke/noice.nvim", event = "VeryLazy" },
  -- ⦄

  -- Editing ⦃
  {
    "tmsvg/pear-tree",
    event = "InsertEnter",
    init = function()
      vim.g.pear_tree_smart_openers = 1
      vim.g.pear_tree_smart_closers = 1
      vim.g.pear_tree_smart_backspace = 1
    end,
  },
  { "echasnovski/mini.ai", config = true },
  { "echasnovski/mini.comment", config = true },
  { "kylechui/nvim-surround", config = true },
  {
    "andymass/vim-matchup",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
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
  -- ⦄

  -- Completion and Diagnostics ⦃
  -- TODO: Set up completion.
  --- ⦄

  -- Language Support ⦃
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })()
    end,
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
          "typst",
          "vim",
          "vimdoc",
          "wgsl",
          "yaml",
          "zig",
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
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
  -- ⦄
}, lazy_config)

-- ⦄

-- Visuals ⦃

-- Use 24-bit colour like it's 1995!
vim.opt.termguicolors = true

-- Load my default colorscheme of choice.
vim.cmd.colorscheme("catppuccin-mocha")

-- The current mode is already displayed in the status line (by Lualine).
vim.opt.showmode = false

-- Modify cursor styling so that...
vim.opt.guicursor = {
  -- the normal, visual, command line normal, and show-match modes use a block
  -- cursor with the default colours defined by the terminal;
  "n-v-c-sm:block",
  -- the insert, command line insert, and visual with selection modes use a
  -- blinking, vertical cursor with colours from the `Cursor` highlight group;
  "i-ci-ve:ver25-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
  -- the replace, command line replace, and operator-pending modes use a
  -- blinking, horizontal cursor with colours from the `Cursor` highlight group;
  "r-cr-o:hor20-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
  -- the built-in terminal uses a blinking, block cursor with colours from the
  -- `TermCursor` highlight group.
  "t:block-blinkon500-blinkoff500-TermCursor",
}

-- ⦄

-- Interface ⦃

map("n", "<leader>q", ":qa<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qa<CR>", { desc = "Force quit" })

-- Disable arrow keys in normal/visual mode so that I can break the habit.
for _, direction in ipairs({ "up", "down", "left", "right" }) do
  map("", "<" .. direction .. ">", "<nop>")
end

-- Set the title of the window if possible.
vim.opt.title = true

-- Always display the sign column to avoid unwarranted jumps.
vim.opt.signcolumn = "yes"

-- Do not wrap lines longer than the window width.
vim.opt.wrap = false

-- Align wrapped lines with the indentation for that line.
vim.opt.breakindent = true

-- Enable flash on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankFlash", {}),
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 300 })
  end,
})

-- Improve the behaviour of search.
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.gdefault = true

-- Start scrolling 4 lines before the edge of the window.
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4

-- Enable relative line numbers.
vim.opt.number = true
vim.opt.relativenumber = true

-- More specifically, use relative line numbers in normal mode and absolute line
-- numbers in insert mode.
local line_number_group = vim.api.nvim_create_augroup("LineNumber", {})
vim.api.nvim_create_autocmd(
  { "BufEnter", "FocusGained", "InsertLeave", "WinEnter" },
  {
    group = line_number_group,
    callback = function()
      if vim.opt.number:get() then
        vim.opt.relativenumber = true
      end
    end,
  }
)
vim.api.nvim_create_autocmd(
  { "BufLeave", "FocusLost", "InsertEnter", "WinLeave" },
  {
    group = line_number_group,
    callback = function()
      if vim.opt.number:get() then
        vim.opt.relativenumber = false
      end
    end,
  }
)

-- Disable line numbers in the integrated terminal and default to insert mode.
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("CustomizeTerminal", {}),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false

    vim.cmd.startinsert()
  end,
})

-- Highlight the line the cursor is on in the currently active buffer.
local cursor_line_group = vim.api.nvim_create_augroup("ShowCursorLine", {})
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  group = cursor_line_group,
  callback = function()
    vim.opt_local.cursorline = true
  end,
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
  group = cursor_line_group,
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

-- Jump to the last known cursor position when opening a file, so long as the
-- position is still valid and we are not editing a commit message (it's likely
-- a different one than last time).
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("RestorePosition", {}),
  callback = function(args)
    local last_posn = vim.fn.line([['"]])

    local is_valid_line = 0 <= last_posn and last_posn <= vim.fn.line("$")
    -- TODO: Investigate replacing this by more generally excluding such files
    -- from shada.
    local is_commit =
      vim.list_contains({ "commit", "jjdescription" }, vim.b[args.buf].filetype)

    if not is_valid_line or is_commit then
      return
    end

    vim.cmd.normal({ args = { 'g`"' }, bang = true })
    -- Deferring this command is somewhat of a hack to ensure that the fold
    -- containing the cursor is expanded since folds can be created (are
    -- created?) _after_ the `BufReadPost` event.
    vim.defer_fn(function()
      vim.cmd.normal({ args = { "zv" }, bang = true })
    end, 5)
  end,
})

-- Automatically create parent directories when saving a file.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("CreateParentDirs", {}),
  callback = function(event)
    local file = vim.uv.fs_realpath(event.match) or event.match

    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    local backup = vim.fn.fnamemodify(file, ":p:~:h")
    backup = backup:gsub("[/\\]", "%%")
    vim.opt_global.backupext = backup
  end,
})

-- ⦄

-- Editing ⦃

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

-- Stop the Rust ftplugin from fucking with the above.
vim.g.rust_recommended_style = false

-- Delete a level of indentation with Shift+Tab.
map("i", "<S-Tab>", "<C-d>")

-- Map Ctrl+Backspace to delete backwards by words.
map("i", "<C-BS>", "<C-w>")

-- Display invisible characters.
vim.opt.list = true
vim.opt.listchars = {
  tab = "•·",
  trail = "·",
  extends = "❯",
  precedes = "❮",
  nbsp = "×",
}

-- Persist undo history.
vim.opt.undofile = true

-- Add dedicated key bindings for yanking to and pasting from the system
-- clipboard.
map({ "n", "v" }, "<C-y>", '"+y', { desc = "Yank to clipboard" })
map({ "n", "v" }, "<C-p>", '"+p', { desc = "Paste from clipboard" })

-- Associate the GLSL filetype with the typical file extensions used for
-- shaders.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("AssociateGlsl", {}),
  pattern = { "*.vert", "*.frag", "*.tesc", "*.geom", "*.comp" },
  callback = function()
    vim.opt_local.filetype = "glsl"
  end,
})

-- ⦄

-- Completion and Diagnostics ⦃

-- Use British English and New Zealand English dictionaries for spell checking.
vim.opt.spelllang = { "en_gb", "en_nz" }

-- Enable spell checking.
vim.opt.spell = true

-- ⦄

-- vim: set et foldlevel=0 foldmethod=marker foldmarker=⦃,⦄:
