
com! -nargs=1 -complete=shellcmd QExec call qrun#exec(<q-args>)
com! -nargs=* -complete=shellcmd QFRun call qrun#qfrun(<q-args>)
com! -nargs=? -complete=file QStdin call <SID>Stdin(<q-args>)
com! -nargs=? -complete=file QTarget call <SID>Target(<q-args>)

fun! s:Stdin(...)
    if a:0 && filereadable(a:1)
        call qrun#bufset('stdin', a:1)
    elseif !exists('b:qrun#stdin')
        call qrun#bufset('stdin', tempname())
    endif
    echo qrun#bufvar('stdin')
endf

fun! s:Target(...)
    if a:0
        call qrun#bufset('bin', a:1)
        echo a:1
    else
        echo qrun#bufvar('bin')
    endif
endf
