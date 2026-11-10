set runtimepath+=.
set runtimepath+=/tmp/plenary.nvim
set runtimepath+=/tmp/telescope.nvim
lua package.path = package.path .. ";/tmp/telescope.nvim/lua/?.lua;/tmp/telescope.nvim/lua/?/init.lua"
syntax on
filetype plugin indent on
