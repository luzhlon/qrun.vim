
let s:luajit_command = 'luajit'

fun! qrun#luajit#init()
    let b:qrun = {}
    if exists('g:qrun#luajit#command')
        let s:luajit_command = g:qrun#luajit#command
    endif
endf

fun! qrun#luajit#run()
    return qrun#exec(printf('%s %s',
                \ s:luajit_command,
                \ shellescape(expand('%:p')))
            \ )
endf
