" =============================================================================
" Filename:     autoload/qrun.vim
" Author:       luzhlon
" Function:     Run a file quickly
" Last Change:  2017/4/23
" =============================================================================

let s:path = expand('<sfile>:p:h')

" Run current file by the file-type {{{
fun! qrun#(...)
    if !exists('b:qrun')
        try
            call qrun#{&ft}#init()
        catch /E117/
            echom 'No qrun extension for current filetype'
            return
        endt
    endif

    try
        update
        let source = expand('%')
        let target = get(b:qrun, 'target')
        if !empty(target) && qrun#older(target, source)
            call qrun#{&ft}#compile(source, target)
        else
            return qrun#{&ft}#run()
        endif
    catch /E117/
        echom 'No qrun extension for current filetype'
    endt
endf " }}}

" If file1 is older then file2 {{{
fun! qrun#older(f1, f2)
    return getftime(a:f1) < getftime(a:f2)
endf " }}}

" Compile with a command and run the target if success {{{
fun! qrun#compile(cmd)
    if exists('s:pid') && job#running(s:pid)
        echom 'A task is running' | return
    endif

    let ft = &filetype
    fun! OnExit(job, code) closure
        if a:code
            bel copen 8 | winc p
        else
            call qrun#{ft}#run()
        endif
    endf

    cexpr ''
    " let cmd = type(a:1)==v:t_list? a:1 : join(a:000)
    let s:pid = job#start(a:cmd, {
                \ 'onout' : 'job#cb_add2qfb',
                \ 'onerr' : 'job#cb_add2qfb',
                \ 'onexit': funcref('OnExit')
                \ })
endf " }}}

" Execute a shell command {{{
if has('win32')
    let g:qrun#new_term_format = 'start cmd /Q /c @call %s'
    let g:qrun#shell_script_ext = '.bat'
    
    fun! s:get_exec_script(cwd, cmd, pause)
        let cwd = iconv(a:cwd, &enc, 'gbk')
        " let ret = ['cd ' . cwd, a:cmd]
        let ret = [a:cmd]
        if a:pause
            call add(ret, '@echo -------- returned %ERRORLEVEL% --------')
            call add(ret, 'pause')
        endif
        return ret
    endf
else
    if executable('cmd.exe')        " WSL
        let g:qrun#new_term_format = 'cmd.exe /c start bash %s'
    else                            " Else unix environment
        if executable('gnome-terminal')
            let g:qrun#new_term_format = "gnome-terminal --display=$DISPLAY -e 'bash %s'"
        elseif executable('deepin-terminal')
            let g:qrun#new_term_format = "deepin-terminal -e bash %s >& /dev/null &"
        else
            echoerr 'Can not find a valid terminal'
        endif
    endif

    let g:qrun#shell_script_ext = '.sh'
    fun! s:get_exec_script(cwd, cmd, pause)
        let ret = ['cd ' . a:cwd, a:cmd]
        if a:pause
            call add(ret, 'echo -en "\033[49;32;1m-------- returned $? --------"')
            call add(ret, 'read')
        endif
        return ret
    endf
endif

"   cmd: command line
"   target: target executable file
"   stdin: standard input file
"   stdout: standard output file
"   cwd: current work directory
"   pause: if pause after executed
"   detach: detach from current terminal
fun! qrun#exec(opt)
    let opt = type(a:opt) == v:t_dict ? a:opt: {'cmd': a:opt}
    let cmd = get(opt, 'cmd')
    if empty(cmd) | let cmd = opt['target'] | endif

    " Build the command line
    let stdin = get(opt, 'stdin', 0)
    let stdout = get(opt, 'stdout', 0)

    let cmd .= empty(stdin) ? '': ' < ' . shellescape(stdin)
    let cmd .= empty(stdout) ? '': ' > ' . shellescape(stdout)

    let cmd = has('win32') ? iconv(cmd, &enc, 'gbk'): cmd

    " Generate the shell script
    let tempfile = qrun#tempfile(g:qrun#shell_script_ext)
    call writefile(
        \ s:get_exec_script(
            \ get(opt, 'cwd', getcwd()),
            \ cmd,
            \ get(opt, 'pause', 1)),
        \ tempfile)
    " Execute the script in a new terminal
    if !exists('g:qrun#new_term_format')
        echom 'Can not open a new terminal, please set the g:qrun#new_term_format'
    else
        let cmd = printf(g:qrun#new_term_format, shellescape(tempfile))
        " echo g:cmd getchar()
        if has('win32')
            exe 'sil! !' cmd
        else
            call system(cmd)
        endif
    endif
endf
" }}}

" Get/set buffer variable in the b:qrun {{{
fun! qrun#bufvar(var, ...)
    if !exists('b:qrun') | let b:qrun = {} | endif
    if a:0 | let b:qrun[a:var] = a:1 | endif
    return get(b:qrun, a:var, '')
endf " }}}

" Get a tempfile with correct encoding {{{
fun! qrun#tempfile(...)
    let suffix = a:0 ? a:1 : ''
    let f = fnamemodify(tempname(), ':r') . suffix
    return has('win32')? iconv(f, 'gbk', &enc): f
endf " }}}

" Open a file {{{
if has('win32')
    let s:env = 'windows'
elseif executable('cmd.exe')
    let s:env = 'wsl'
else
    let s:env = 'unix'
endif

fun! qrun#open(file)
    let f = shellescape(a:file)
    if s:env == 'windows' || s:env == 'wsl'
        sil exe '!rundll32.exe url.dll,FileProtocolHandler' f
    else
        sil exe '!xdg-open' f
    endif
endf
" }}}

fun! qrun#modeline()
    return matchstr(getline('$'), 'qrun\.vim:\s*\zs.*')
endf
