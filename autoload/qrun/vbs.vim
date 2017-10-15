
fun! qrun#python#init()
    let b:qrun = {}
endf

fun! qrun#python#run()
    call qrun#exec('cscript.exe ' . shellescape(expand('%')))
endf
