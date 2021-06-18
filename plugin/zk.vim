if exists('g:loaded_zk') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if !has('nvim-0.5.0')
    echohl Error
    echom '[zk.nvim] This plugin presently only supports neovim versions: nightly, >=0.5.0'
    echohl clear
    finish
endif

let g:loaded_zk = 1

" NOTE: we require that the user runs setup themselves.."
" lua require('zk').setup({})

augroup zk
    autocmd FileType markdown lua require('zk').setup_keymaps()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
