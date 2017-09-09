
com! -nargs=1 -complete=shellcmd QExec call qrun#exec(<q-args>)
com! -nargs=* -complete=shellcmd QFRun call qrun#qfrun(<q-args>)
com! -nargs=? -complete=file QStdin call <SID>Stdin(<q-args>)
com! -nargs=? -complete=file QTarget call <SID>Target(<q-args>)
com! QDebug call <SID>Debug()

fun! s:Debug()
    if !exists('g:qrun#debugger')
        echom 'Please specify a dbugger by g:qrun#debugger'
        return
    endif
    let bin = qrun#bufvar('bin')
    if empty(bin)
        echom 'There is no target binary to debug'
        return
    endif
    if g:qrun#debugger =~? 'windbg\(\.exe\)\?'
        silent exe printf('!start "%s" -srcpath "%s" -y "%s" "%s"',
                    \ g:qrun#debugger, expand('%:p:h'), fnamemodify(bin, ':p:h'), bin)
    endif
endf

fun! s:Stdin(...)
    if a:0 && filereadable(a:1)
        call qrun#bufvar('stdin', a:1)
    elseif !exists('b:qrun#stdin')
        call qrun#bufvar('stdin', tempname())
    endif
    echo qrun#bufvar('stdin')
endf

fun! s:Target(...)
    if a:0 && !empty(a:1)
        call qrun#bufvar('bin', a:1)
        echo a:1
    else
        echo qrun#bufvar('bin')
    endif
endf
