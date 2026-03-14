
" General Settings

set autoindent                 " New lines inherit the indentation of previous lines
set autoread                   " Pick up external changes to files without confirmation
set backspace=indent,eol,start " Allow backspace in insert mode
set cmdheight=2                " Set the command window height to 2 lines, to avoid repeatedly pressing ENTER to continue
set confirm                    " If a command fails because of unsaved changes, raise a save file dialogue window
set cursorline                 " Highlight the current line and column
set encoding=UTF-8
set expandtab
set formatoptions=l            " Don't break long lines in insert mode.
set history=1000               " Store lots of :cmdline history
set hlsearch                   " highlight text while searching
set ignorecase                 " Ignore case when searching
set incsearch
set linebreak                  " While wrapping, don't break words and instead break at spaces
set mouse=a                    " Enable mouse for scrolling and resizing
set mousemodel=popup
set nobackup                   " Turn-off backup
set nostartofline              " Stop certain movements from always going to the first character of a line
set noswapfile                 " Turn-off swap files
set nowritebackup              " Turn-off write backup
set number                     " Show line numbers
set shiftwidth=4
set shortmess=a
set showcmd                    " Show incomplete cmds down the bottom
set smartcase
set smartindent                " Switch search to case-sensitive when search query contains an uppercase letter
set softtabstop=4
set showtabline=1              " Show tab line if more than one tab open
set spell
set spelllang=en_us,en_gb
set splitbelow                 " Split below current window
set splitright                 " Split window to the right
set tabstop=4
set termguicolors
set title                      " Set the terminals title as the filename
set titlelen=0                 " Don’t abbreviate the filename in terminal titles
set visualbell                 " Use visual bell instead of beeping when doing something wrong
set whichwrap+=<,>,[,]         " Make the left and right arrow keys change line
set wildmode=longest,list,full

" Vim with default settings does not allow easy switching between multiple files in the same editor window.
" Users can use multiple split windows or multiple tab pages to edit multiple files, but it is still best to enable
" an option to allow easier switching between files.
" One such option is the 'hidden' option, which allows you to re-use the same window and switch from an unsaved buffer
" without saving it first. Also allows you to keep an undo history for multiple files when re-using the same window in
" this way. Note that using persistent undo also lets you undo in multiple files even in the same window, but is less
" efficient and is actually designed for keeping undo history after closing Vim entirely. Vim will complain if you try
" to quit without saving, and swap files will keep you safe if your computer crashes.
set hidden

" Set cut, copy & paste from system clipboard instead of internal buffers
if has('unnamedplus')
    set clipboard=unnamed,unnamedplus
else
    set clipboard=unnamed
endif

" --------------------------------------------------------------------------------------------------------------------- "

" Set the working directory to the location with which Neovim was invoked
" '%' gives the name of the current file, '%:p' gives its full path, and '%:p:h' gives its head (directory)

cd %:p:h

" --------------------------------------------------------------------------------------------------------------------- "

" Set syntax highlighting for special files

au BufRead,BufNewFile *.aliases              set syntax=sh
au BufRead,BufNewFile *.bash*                set syntax=sh
au BufRead,BufNewFile *.exports              set syntax=sh
au BufRead,BufNewFile *.hardware_description set syntax=json
au BufRead,BufNewFile *.shell                set syntax=sh
au BufRead,BufNewFile *.xc                   set syntax=xc " provided by ../syntax/xc.vim
au BufRead,BufNewFile *.zsh*                 set syntax=sh

" --------------------------------------------------------------------------------------------------------------------- "

" Set leader key to Space

let mapleader=" "

" <leader> + S will reload editor config
nnoremap <leader>s :source ~/.config/nvim/init.vim<CR>

" <leader> + n shows you the netrw file explorer
nnoremap <leader>n :Explore<CR>

nnoremap Q <nop>

" --------------------------------------------------------------------------------------------------------------------- "

"Move cursor by display lines when wrapping

nnoremap <expr> <Up>   (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> <Down> (v:count == 0 ? 'gj' : 'j')
vnoremap <expr> <Up>   (v:count == 0 ? 'gk' : 'k')
vnoremap <expr> <Down> (v:count == 0 ? 'gj' : 'j')
inoremap <expr> <Up>   (v:count == 0 ? '<C-o>gk' : '<C-o>k')
inoremap <expr> <Down> (v:count == 0 ? '<C-o>gj' : '<C-o>j')

nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
vnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
vnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

" --------------------------------------------------------------------------------------------------------------------- "

" Move a line/block up/down using Ctrl + j/k/Up/Down

nnoremap <C-j>         :m .+1<CR>==
inoremap <C-j><Esc>    :m .+1<CR>==gi
vnoremap <C-j>         :m '>+1<CR>gv=gv
nnoremap <C-k>         :m .-2<CR>==
inoremap <C-k><Esc>    :m .-2<CR>==gi
vnoremap <C-k>         :m '<-2<CR>gv=gv

nnoremap <C-Down>      :m .+1<CR>==
inoremap <C-Down><Esc> :m .+1<CR>==gi
vnoremap <C-Down>      :m '>+1<CR>gv=gv
nnoremap <C-Up>        :m .-2<CR>==
inoremap <C-Up><Esc>   :m .-2<CR>==gi
vnoremap <C-Up>        :m '<-2<CR>gv=gv

" --------------------------------------------------------------------------------------------------------------------- "

" Ctrl-S saves file in Normal and insert modes

nnoremap <C-s> :w <CR>
imap  <C-s> <esc> :w<CR>

" --------------------------------------------------------------------------------------------------------------------- "

" Ctrl-Backspace to delete the previous word in insert mode

noremap! <C-BS> <C-w>
noremap! <C-h> <C-w>

" --------------------------------------------------------------------------------------------------------------------- "

" Toggle soft wrap (Alt+Z — same as VS Code, Zed, Micro)

nnoremap <A-z> :set wrap!<CR>

" --------------------------------------------------------------------------------------------------------------------- "
