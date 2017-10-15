
call assert_true(executable('cmd.exe'))

fun! qrun#dosbatch#init()
    let b:qrun = {}
endf

fun! qrun#dosbatch#run()
    exe '!start cmd.exe /c @call' shellescape(expand("%"))
endf
