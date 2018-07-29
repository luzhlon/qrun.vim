
fun! qrun#autohotkey#init()
    let b:qrun = {}
endf

fun! qrun#autohotkey#run()
    if has_key(g:, 'qrun#autohotkey#path')
        exe 'silent !start' shellescape(g:qrun#autohotkey#path) shellescape(@%)
    else
        echoerr 'Please set the autohotkey path: g:qrun#autohotkey#path'
    endif
endf
