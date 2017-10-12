
" Get the path of fasm
let s:fasm_path = exepath('fasm')
if empty(s:fasm_path)
    echom 'Not found fasm'
    finish
endif

let s:inc_path = fnamemodify(s:fasm_path, ':h') . '/INCLUDE'
if !isdirectory(s:inc_path)
    echom 'Not found include path for fasm'
    finish
endif

fun! qrun#fasm#init()
    let b:qrun = {'target': qrun#tempfile('.exe')}
endf

fun! qrun#fasm#compile(source, target)
    let orgin_inc = $INCLUDE
    let $INCLUDE = s:inc_path
    " Build && run
    call qrun#compile(['fasm', a:source, a:target])
    let $INCLUDE = orgin_inc
endf

fun! qrun#fasm#run()
    return qrun#exec(b:qrun)
endf
