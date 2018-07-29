
if !exists('g:qrun#python#progcmd')
    let g:qrun#python#progcmd = executable('ipython') ? 'ipython --no-banner': 'python'
endif

if !exists('g:qrun#python3#progcmd')
    let g:qrun#python3#progcmd = executable('ipython3') ? 'ipython3 --no-banner': 'python3'
endif

if !exists('g:qrun#pythonw#progcmd')
    let g:qrun#pythonw#progcmd = 'pythonw'
endif

fun! qrun#python#init()
    let b:qrun = {}
endf

fun! qrun#python#run()
    " Use python3 default
    let progcmd = getline(1) =~ 'python$' ?
                \ g:qrun#python#progcmd   :
                \ g:qrun#python3#progcmd

    if expand('%:e') == 'pyw'
        let progcmd = g:qrun#pythonw#progcmd
    endif

    let m = qrun#modeline()
    let cmd = [progcmd]
    if m =~ '^\w\+'             " Use this progcmd
        let cmd = [m]
    else                        " Add flags
        call add(cmd, m)
    endif
    call add(cmd, shellescape(expand('%')))
    let cmd = join(cmd)

    " echo cmd | call getchar()
    if cmd =~ '^pythonw'
        sil! exe '!start' cmd
    else
        call qrun#exec(cmd)
    endif
endf
