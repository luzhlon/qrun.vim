" =============================================================================
" Filename:     autoload/qrun.vim
" Author:       luzhlon
" Function:     Run a file quickly
" Last Change:  2017/4/23
" =============================================================================

let s:path = expand('<sfile>:p:h')
" Find the visual studio directory and it's toolchains
fun! qrun#vcvarsall()
    let fpy = s:path . '/find-vcvars.py'
    exe 'py3f' fpy
    return py3eval('_')
endf

fun! s:CheckCxxCompiler()
    " Check compiler
    if has('win32') && executable('cl')
        fun! T(s, o)
            let obj = fnamemodify(a:o, ':p:r')
            call qrun#qfrun(['cl', a:s, '/Fe:', a:o, '/Fo:', obj, '/Fd:', obj, '/Zi'])
        endf
        let g:QRunCompCxx = funcref('T')
        compiler msvc
    elseif executable('g++')
        let g:QRunCompCxx = {s, o->qrun#qfrun(['g++', '-std=c++11', s, '-o', o])}
        compiler gcc
    elseif executable('clang++')
        let g:QRunCompCxx = {s, o->qrun#qfrun(['clang++', '-std=c++11', s, '-o', o])}
        compiler gcc
    else
        let g:QRunCompCxx = ''
    endif
endf

fun! s:tempfile(ex)
    let f = fnamemodify(tempname(), ':r') . a:ex
    return has('win32')? iconv(f, 'gbk', 'utf-8'): f
endf

fun! s:cmdline(opt)
    let bin = a:opt.bin
    if has('win32')
        let bin = iconv(bin, 'utf8', 'gbk')
    endif
    let stdin = get(a:opt, 'stdin', 0)
    let stdout = get(a:opt, 'stdout', 0)
    if !empty(stdin)
        let bin .= ' > ' . shellescape(stdin)
    endif
    if !empty(stdout)
        let bin .= ' > ' . shellescape(stdout)
    endif
    return bin
endf

" Execute a command
if has('win32')
    fun! qrun#exec(bin, ...)
        " Construct the command lines
        let opt = a:0 ? a:1 : {'bin': a:bin}
        let cont = [s:cmdline(opt), 'echo [returned %ERRORLEVEL%]']
        if get(opt, 'pause', 1)
            call add(cont, 'pause')
        endif
        let tf = tempname() . '.bat'
        call writefile(cont, tf)
        silent exe '!start cmd /Q /c' shellescape('@call ' . tf)
    endf
elseif executable('cmd.exe')        " WSL
    fun! qrun#exec(bin, ...)
        let opt = a:0 ? a:1 : {'bin': a:bin}
        let cont = ['cd ' . getcwd(),
                \ s:cmdline(opt),
                \ 'echo -n [returned $?]']
        if get(opt, 'pause', 1)
            call add(cont, 'read')
        endif
        let tf = tempname()
        call writefile(cont, tf)
        silent exe printf('!cmd.exe /c start bash %s', tf)
        redraw!
    endf
else                                " Else linux
    fun! s:getscript(opt)
        let cont = ['cd ' . getcwd(), s:cmdline(a:opt), 'echo -n [returned $?]']
        if get(a:opt, 'pause', 1)
            call add(cont, 'read')
        endif
        let tf = tempname()
        call writefile(cont, tf)
        return tf
    endf
    fun! s:exec_in_term(opt)
        if !exists('s:terminal')
            if executable('gnome-terminal')
                let s:terminal = 'gnome-terminal --display=$DISPLAY'
            else
                let s:terminal = ''
            endif
        endif
        if empty(s:terminal)
            echo 'NO TERMINAL' | return 0
        endif
        call system(join([s:terminal, printf("-e 'bash %s'", s:getscript(a:opt))]))
        return 1
    endf
    fun! qrun#exec(bin, ...)
        let opt = a:0 ? a:1 : {'bin': a:bin}
        " Try run the command in a external terminal
        if s:exec_in_term(opt) | return | endif
        " Normal excute
        let cmd = s:cmdline(opt)
        let pause = get(opt, 'pause', 1)
        if has('nvim')
            for i in range(1, winnr('$'))
                let bt = getbufvar(winbufnr(i), '&bt')
                if bt == 'terminal'
                    exe i 'winc w'
                    call feedkeys("i\<c-u>" . cmd . "\<cr>", 'n')
                    break
                endif
            endfo
        else
            exe (pause ? '!': 'sil!') cmd
            redraw!
        endif
    endf
endif

" Execute a command
fun! s:execute(cmd)
    let cmd = a:cmd
    return qrun#exec(cmd, b:qrun)
endf

fun! s:onexit(job, code)
    if a:code
        bel copen 8 | winc p
    else
        call g:QRunSuccess()
    endif
endf
" Run a job and put it's output to quickfix
fun! qrun#qfrun(...)
    if !a:0 | return | endif
    if exists('s:pid')&&job#running(s:pid)
        echom 'A task is running'
    return|endif
    cexpr ''
    let cmd = type(a:1)==v:t_list? a:1 : join(a:000)
    let s:pid = job#start(cmd, { 'onout' : 'job#cb_add2qfb',
                                \'onerr' : 'job#cb_add2qfb',
                                \'onexit': funcref('s:onexit')})
endf
" Get/set buffer variable
fun! qrun#bufvar(var, ...)
    if !exists('b:qrun') | let b:qrun = {} | endif
    if a:0 | let b:qrun[a:var] = a:1 | endif
    return get(b:qrun, a:var, '')
endf
" return if the f1 is new than f2
fun! qrun#new(f1, f2)
    return getftime(a:f1) > getftime(a:f2)
endf
" Set the environtment variable INCLUDE LIB PATH
fun! s:setenvs()
    let vvpath = qrun#vcvarsall()
    if !empty(vvpath)
        let tf = tempname()
        let tbat = tempname() . '.bat'
        let cont = join(['@echo off',
            \ printf('call "%s" x64 > nul', vvpath),
            \ printf('echo %%INCLUDE%%>"%s"', tf),
            \ printf('echo %%LIB%%>>"%s"', tf),
            \ printf('echo %%PATH%%>>"%s"', tf), ''], "\n")
        call system('cmd', cont)
        let cont = readfile(tf)
        let $INCLUDE = cont[0]
        let $LIB = cont[1]
        let $PATH = cont[2]
    endif
endf
" Run a C++/C source file quickly
fun! qrun#cxx()
    if has('win32') && !exists('$INCLUDE')
        call s:setenvs()
    endif
    if !exists('g:QRunCompCxx')
        call s:CheckCxxCompiler()
    endif
    if empty(g:QRunCompCxx)
        echom 'No cxx compiler can be found'
        return
    endif
    update
    let bin = qrun#bufvar('bin')
    if empty(bin)
        let bin = s:tempfile('.exe')
        call qrun#bufvar('bin', bin)
    endif
    let g:QRunSuccess = {->s:execute(bin)}
    " The source file is newer than binary
    if qrun#new(expand('%'), bin)
        call g:QRunCompCxx(expand('%'), fnameescape(bin))
    else
        call g:QRunSuccess()
    endif
endf
" Run a java source file quickly
fun! qrun#java()
    if !executable('javac')
        echo 'javac not available'
        return
    endif
    compiler javac
    update
    if !exists('b:binfile')
        let b:binfile = expand('%') . '.class'
    endif
    if !empty(s:qrun#stdin)
        call add(g:RunSuccess, '< ' . s:qrun#stdin)
    endif
    let g:RunSuccess = [printf('QExec java %s', expand('%:r'))]
    let g:RunSuccess = join(g:RunSuccess)
    if getftime(expand('%')) > getftime(b:binfile)
        call qrun#qfrun(['javac', expand('%')])
    else
        exe g:RunSuccess
    endif
endf
