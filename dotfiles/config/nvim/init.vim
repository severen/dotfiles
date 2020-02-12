" Preamble {{{

let prefix = '~/.local/share/nvim/'

" Install vim-plug if it is not installed.
if empty(glob(prefix . 'site/autoload/plug.vim'))
  silent !curl -fLo ~/.nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

" }}}

" Plugins {{{
call plug#begin(prefix . 'plugged')

" Editing {{{
Plug 'kana/vim-operator-user'
Plug 'haya14busa/vim-operator-flashy'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-speeddating'
Plug 'unblevable/quick-scope'
Plug 'glts/vim-magnum'
Plug 'glts/vim-radical'
Plug 'tmsvg/pear-tree'
Plug 'andymass/vim-matchup'
Plug 'editorconfig/editorconfig-vim'
" }}}

" Completion, Snippets, and Diagnostics {{{
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'SirVer/ultisnips'
Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
\}
" }}}

" Language Support {{{
Plug 'sheerun/vim-polyglot'
Plug 'lervag/vimtex'
" }}}

" Interface {{{
Plug 'liuchengxu/vim-which-key', { 'on': ['WhichKey', 'WhichKey!'] }
Plug 'simnalamburt/vim-mundo', { 'on': ['MundoShow', 'MundoToggle'] }
Plug 'junegunn/fzf.vim'
Plug 'Lokaltog/neoranger', { 'on': ['Ranger', 'RangerCurrentFile' ] }
Plug 'justinmk/vim-dirvish'
Plug 'tpope/vim-eunuch'
" TODO: Evaluate whether is.vim is a better choice or not.
Plug 'markonm/traces.vim'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'junegunn/goyo.vim', { 'on': ['Goyo'] }
Plug 'junegunn/limelight.vim', { 'on': ['Limelight'] }
" }}}

" Visuals {{{
Plug 'ayu-theme/ayu-vim'
Plug 'itchyny/lightline.vim'
" }}}

" Source Control {{{
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'mhinz/vim-signify'
" }}}

call plug#end()
" }}}

" Basics {{{

" Improve performance when executing macros.
set lazyredraw

" This is required by some plugins in order to improve responsiveness.
set updatetime=100

" }}}

" Visuals {{{

set termguicolors
let ayucolor="mirage"
colorscheme ayu

" TODO: Display a trailing whitespace warning in the modeline.
let g:lightline = {
  \ 'colorscheme': 'ayu_mirage',
\}

" }}}

" Keybindings {{{

let g:mapleader = "\<Space>"
let g:maplocalleader = '\\'

" Display which-key's prompt for leader and local leader.
nnoremap <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
nnoremap <silent> <localleader> :<c-u>WhichKey '\\'<CR>

" Top-level bindings {{{
nnoremap <silent> <Leader>, :Buffers<CR>
nnoremap <silent> <Leader>. :Files<CR>
" }}}

" File-related bindings {{{
nnoremap <silent> <Leader>ff :Files<CR>
nnoremap <silent> <Leader>fh :History<CR>
nnoremap <silent> <Leader>ft :Filetypes<CR>
nnoremap <silent> <Leader>fu :MundoToggle<CR>
nnoremap <silent> <Leader>fb :Ranger<CR>
" }}}

" Buffer-related bindings {{{
nnoremap <silent> <Leader>bb :Buffers<CR>
nnoremap <silent> <Leader>bd :bdelete<CR>
" }}}

" Help-related bindings {{{
nnoremap <silent> <Leader>h :Helptags<CR>
" }}}

" Toggle-related bindings {{{
nnoremap <silent> <Leader>tg :Goyo<CR>
" }}}

" Delete a level of identation on backtab.
inoremap <S-Tab> <C-d>

" }}}

" Editing {{{

" Use 2 spaces for identation.
set tabstop=2
set shiftwidth=2
set expandtab

" Round indents to multiples of shiftwidth when using >> and <<.
set shiftround

" Enable persistent undo.
set undofile

" Copy and paste to the system clipboard.
set clipboard+=unnamedplus

" Use British and New Zealand dictionaries for spell checking.
set spelllang=en_gb,en_nz

" Enable Quickscope's highlighting for these keys.
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Enable flashing the yanked region with vim-operator-flashy.
map y <Plug>(operator-flashy)
nmap Y <Plug>(operator-flashy)$

" }}}

" Interface {{{

" Enable full mouse support.
set mouse=a

" Disable annoying prompts when switching between modified buffers.
set hidden

" Use relative line numbers in normal mode and absolute line numbers in insert
" mode.
set number relativenumber
augroup LineNumbers
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu | set rnu | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave * if &nu | set nornu | endif
augroup END

" Highlight the line the cursor is on in the currently active buffer
augroup CursorLine
  autocmd!
  autocmd VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline
augroup END

" Display invisible characters.
set list
set listchars=tab:•·,trail:·,extends:❯,precedes:❮,nbsp:×

" Improve the behaviour of search.
set ignorecase
set smartcase
set gdefault

" Colourise colour codes with nvim-colorizer.
lua << EOF
  require 'colorizer'.setup {
    'css';
    'scss';
    'javascript';
    html = {
      mode = 'foreground';
    }
  }
EOF

" Enable Limelight when Goyo is enabled.
augroup LimelightGoyo
  autocmd! User
  autocmd User GoyoEnter Limelight
  autocmd User GoyoLeave Limelight!
augroup END

" }}}

" Completion, Snippets, and Diagnostics {{{

" TODO: Rebind gd and others to use a language server _only_ when available.
let g:LanguageClient_serverCommands = {
  \ 'c': ['clangd', '--clang-tidy', '--header-insertion=never', '--compile-commands-dir=build'],
  \ 'cpp': ['clangd', '--clang-tidy', '--header-insertion=never', '--compile-commands-dir=build'],
  \ 'rust': ['rustup', 'run', 'stable', 'rls'],
  \ 'python': ['python', '-m', 'pyls'],
  \ 'sh': ['bash-language-server', 'start'],
\}
nnoremap <silent> <F5> :call LanguageClient_contextMenu()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>

" Completion {{{

let g:deoplete#enable_at_startup = 1
call deoplete#custom#option({
  \ 'smart_case': 1,
  \ 'refresh_always': 1,
  \ 'ignore_sources': {'_': ['around', 'buffer']},
\})

" Improve the behaviour of the built-in completion.
set completeopt+=menuone,noinsert
set completeopt-=preview

" Use fzf for built-in completion prompts
imap <c-x><c-k> <Plug>(fzf-complete-word)
imap <c-x><c-f> <Plug>(fzf-complete-path)
imap <c-x><c-j> <Plug>(fzf-complete-file-ag)
imap <c-x><c-l> <Plug>(fzf-complete-line)

" }}}

" Change snippet directory
let g:UltiSnipsSnippetDirectories=["ultisnips"]

" }}}

" Language Support {{{

" LaTeX {{{

" Polyglot's LaTeX syntax is made obsolete by VimTeX.
let g:polyglot_disabled = ['latex']
call deoplete#custom#var('omni', 'input_patterns', {
  \ 'tex': g:vimtex#re#deoplete,
\})

" This is not very useful with VimTeX and has a risk of annoying false
" positives.
let g:tex_no_error = 1

" }}}

" }}}

" vim: set et foldlevel=0 foldmethod=marker:
