
fun! qrun#vimlua#init()
    let b:qrun = {}
endf

fun! qrun#vimlua#run()
    exec 'luafile' expand('%')
endf
