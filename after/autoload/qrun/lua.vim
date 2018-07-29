
fun! qrun#lua#init()
    let b:qrun = {}
endf

fun! qrun#lua#run()
    return qrun#exec(
            \ printf('lua %s', shellescape(expand('%:p')))
            \ )
endf
