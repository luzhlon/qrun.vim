" =============================================================================
" Filename:     autoload/qrun.vim
" Author:       luzhlon
" Function:     Run a file quickly
" Last Change:  2017/4/23
" =============================================================================

" Check compiler
if !exists('g:QRunCompCxx')
    if has('win32') && executable('cl')
        let g:QRunCompCxx = {s, o->qrun#qfrun(['cl', s, '/Fo:', fnamemodify(o, ':p:r'), '/Fe:', o])}
        compiler msvc
    elseif executable('g++')
        let g:QRunCompCxx = {s, o->qrun#qfrun(['g++', '-std=c++11', s, '-o', o])}
        compiler gcc
    elseif executable('clang++')
        let g:QRunCompCxx = {s, o->qrun#qfrun(['clang++', '-std=c++11', s, '-o', o])}
        compiler gcc
    endif
endif

fun! s:tempfile(ex)
    let f = fnamemodify(tempname(), ':r') . a:ex
    return has('win32')? iconv(f, 'gbk', 'utf-8'): f
endf

" Execute a command
fun! s:execmd(cmd)
    if has('win32')
        exe 'sil' '!start' a:cmd
    else
        exe '!' a:cmd
    endif
endf
" Execute a command
fun! qrun#exec(cmd)
    let cmd = a:cmd
    let stdin = qrun#bufvar('stdin')
    if !empty(stdin)
        let cmd = printf('%s < %s', cmd, stdin)
    endif
    if has('nvim')
        for i in range(1, winnr('$'))
            let bt = getbufvar(winbufnr(i), '&bt')
            if bt == 'terminal'
                exe i 'winc w'
                call feedkeys("i\<c-u>")
                call feedkeys(cmd)
                call feedkeys("\<cr>")
            endif
        endfo
    else
        return s:execmd(cmd)
    endif
endf

fun! s:onexit(job, code)
    if a:code
        copen | winc p
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

fun! qrun#bufset(var, val)
    if !exists('b:qrun')
        let b:qrun = {}
    endif
    let b:qrun[a:var] = a:val
endf

fun! qrun#bufvar(var, ...)
    if !exists('b:qrun')
        let b:qrun = {}
    endif
    if !has_key(b:qrun, a:var) && a:0
        let b:qrun[a:var] = a:1
    endif
    return get(b:qrun, a:var, 0)
endf
" return if the f1 is new than f2
fun! qrun#new(f1, f2)
    return getftime(a:f1) > getftime(a:f2)
endf

fun! qrun#cxx()
    if exists('g:QRunCompCxx')
        update
        let bin = qrun#bufvar('bin', s:tempfile('.exe'))
        let g:QRunSuccess = {->qrun#exec(bin)}
        " The source file is newer than binary
        if qrun#new(expand('%'), bin)
            call g:QRunCompCxx(expand('%'), fnameescape(bin))
        else
            call g:QRunSuccess()
        endif
    else
        echo 'No cxx compiler can be found'
    endif
endf

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
