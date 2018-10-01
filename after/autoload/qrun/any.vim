
fun! qrun#any#init()
    let b:qrun = {}
endf

fun s:sub(m)
    let a = a:m[0]
    return shellescape(expand(a))
endf

fun! qrun#any#run()
    let cmdline = qrun#modeline()
    let cmdline = substitute(cmdline, '%[a-zA-Z:]*', funcref('s:sub'), 'g')
    call qrun#exec(cmdline)
endf
