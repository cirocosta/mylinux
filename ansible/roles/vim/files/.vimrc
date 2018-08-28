execute pathogen#infect()

syntax on

" Tie the clipboard to the `*` register so that we can yank to
" and paste from whatever we yank.
set clipboard=unnamed

" Create an undo directory such that we can go back in time by
" having the UNDOFILE directive set.
"
" By keeping them all under a single directory, we make sure
" that they don't live in random places.
set undodir=~/.vim_runtime/temp_dirs/undodir
set undofile

" Escape with smashing j and k; easier to press quickly on 
" slow systems.
inoremap jk <esc>
inoremap kj <esc>

" Save on enter.
nmap <cr> :w<cr>

" Clear highlights on space.
nmap <space> :noh<cr>

" Open NERDTree whenever pressing minus (hyphen)
nmap - :NERDTree<cr>

" Shorthand for window switching.
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Jump to the definition when using `gd` combination
nmap gd :YcmCompleter GoToDefinition<cr>

" Don't create swap file.
set noswapfile

" Highlight the search results.
set hlsearch

" Do not show preview option
set completeopt-=preview

" Automatically indent
set autoindent
set smartindent

" Break lines when max-width is hit
set linebreak

" Ignore case when searching
set ignorecase

" Make NERDTree show hidden files
let NERDTreeShowHidden=1

" Show bottom-right numbers
set ruler
