if exists('g:loaded_zk') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if !has('nvim')
    echohl Error
    echom "Sorry this plugin only works with versions of neovim that support lua: nightly, >=0.5.0"
    echohl clear
    finish
endif

let g:loaded_zk = 1

highlight default ZkThing guifg=#89d957 guibg=NONE gui=bold
highlight default link ZkStuff Normal

" Zk builtin lists
" function! s:zk_complete(arg,line,pos)
"   let l:builtin_list = luaeval('vim.tbl_keys(require("telescope.builtin"))')
"   " let l:extensions_list = luaeval('vim.tbl_keys(require("telescope._extensions").manager)')
"   " let l:options_list = luaeval('vim.tbl_keys(require("telescope.config").values)')
"   " let l:extensions_subcommand_dict = luaeval('require("telescope.command").get_extensions_subcommand()')

"   let list = [extend(l:builtin_list,l:extensions_list),l:options_list]
"   let l = split(a:line[:a:pos-1], '\%(\%(\%(^\|[^\\]\)\\\)\@<!\s\)\+', 1)
"   let n = len(l) - index(l, 'Telescope') - 2

"   if n == 0
"     return join(list[0],"\n")
"   endif

"   if n == 1
"     if index(l:extensions_list,l[1]) >= 0
"       return join(get(l:extensions_subcommand_dict, l[1], []),"\n")
"     endif
"     return join(list[1],"\n")
"   endif

"   if n > 1
"     return join(list[1],"\n")
"   endif
" endfunction

" " Zk Commands with complete
" command! -nargs=* -complete=custom,s:zk_complete Zk    lua require('zk.command').load_command(<f-args>)

function! s:zk_complete(...)
  return join(luaeval('require("zk.command").command_list()'),"\n")
endfunction

" Zk Commands with complete
command! -nargs=+ -complete=custom,s:zk_complete Zk    lua require('zk.command').load_command(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
