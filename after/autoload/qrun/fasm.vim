
" Get the path of fasm
let s:fasm_path = exepath('fasm')
if empty(s:fasm_path)
    echom 'Not found fasm'
    finish
endif

let s:inc_path = fnamemodify(s:fasm_path, ':h') . '/INCLUDE'
if isdirectory(s:inc_path)
    let $INCLUDE .= (has('win32') ? ';': ':') . s:inc_path
    call setbufvar(bufnr('%'), '&path', s:inc_path)
else
    echom 'Not found include path for fasm' | finish
endif

fun! qrun#fasm#init()
    let b:qrun = {'target': qrun#tempfile('.exe')}
endf

fun! qrun#fasm#compile(source, target)
    " Build && run
    call qrun#compile(['fasm', a:source, a:target])
endf

fun! qrun#fasm#run()
    return qrun#exec(b:qrun)
endf
