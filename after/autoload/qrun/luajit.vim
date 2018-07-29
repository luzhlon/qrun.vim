
let s:luajit_command = 'luajit32'

fun! qrun#luajit#init()
    let b:qrun = {}
    if exists('g:qrun#luajit#command')
        let s:luajit_command = g:qrun#luajit#command
    endif
endf

fun! qrun#luajit#run()
    compiler! lua
    if qrun#option('x64') || qrun#modeline() == 'x64'
        let s:luajit_command = 'luajit64'
    endif
    call qrun#errun([s:luajit_command, expand('%:p')])
    winc p
endf
