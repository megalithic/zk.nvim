if exists('g:loaded_zk') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if !has('nvim')
    echohl Error
    echom "[zk.nvim] This plug presently only supports neovim versions: nightly, >=0.5.0"
    echohl clear
    finish
endif

let g:loaded_zk = 1

lua require('zk').init()

let &cpo = s:save_cpo
unlet s:save_cpo
