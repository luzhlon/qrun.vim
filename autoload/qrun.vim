" =============================================================================
" Filename:     autoload/qrun.vim
" Author:       luzhlon
" Function:     Run a file quickly
" Last Change:  2017/4/23
" =============================================================================

let s:path = expand('<sfile>:p:h')
let s:cadde = {j,d,e->vim#cadde(d)}

" Run current file by the file-type {{{
fun! qrun#(...)
    let ft = qrun#gettype()
    if !exists('b:qrun')
        try
            call qrun#{ft}#init()
        catch /E117/
            echom 'No qrun extension for current filetype'
            return
        endt
    endif

    try
        update
        call extend(b:qrun, a:0 ? a:1 : {})
        let source = expand('%')
        let target = get(b:qrun, 'target')
        if !empty(target) && qrun#older(target, source)
            call qrun#{ft}#compile(source, target)
        elseif get(b:qrun, 'run', 1)
            return qrun#{ft}#run()
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
    if exists('s:pid') && job#status(s:pid) == 'run'
        echom 'A task is running' | return
    endif

    let ft = &filetype
    let cmd = a:cmd
    fun! OnExit(job, code, stream) closure
        if a:code
            bel copen 8 | winc p
        elseif get(b:qrun, 'run', 1)
            call qrun#{ft}#run()
            echom 'Build success:' cmd
        endif
    endf

    cexpr ''
    " let cmd = type(a:1)==v:t_list? a:1 : join(a:000)
    let s:pid = job#start(cmd, {
                \ 'on_stdout' : s:cadde,
                \ 'on_stderr' : s:cadde,
                \ 'on_exit': funcref('OnExit')
                \ })
endf " }}}

" Execute a shell command in a external terminal {{{
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
"   term: if use terminal builtin
fun! qrun#exec(opt)
    let opt = type(a:opt) == v:t_dict ? a:opt: {'cmd': a:opt}
    let cmd = get(opt, 'cmd')
    if empty(cmd) | let cmd = opt['target'] | endif

    " Build the command line
    let stdin = get(opt, 'stdin', 0)
    let stdout = get(opt, 'stdout', 0)
    let useterm = get(opt, 'term', 0)
    if !exists('g:qrun#new_term_format')
        let useterm = 1
    endif

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
    let tempfile = shellescape(tempfile)
    " Execute the script in a new terminal
        " echom 'Can not open a new terminal, please set the g:qrun#new_term_format'
    if useterm
        if !exists(':terminal')
            echo 'Current version is not supports :terminal command'
            return
        endif
        if has('nvim') | winc s | endif
        if has('win32')
            exec 'terminal' 'cmd /Q /c @call' tempfile
        else
            exec 'terminal' 'bash' tempfile
        endif
        startinsert
    else
        let cmd = printf(g:qrun#new_term_format, tempfile)
        " echo g:cmd getchar()
        if has('win32')
            exe 'sil! !' cmd
        else
            call system(cmd)
        endif
    endif
endf
" }}}

" Execute cmdline in built-in terminal {{{
fun! qrun#texec(cmd)
    call term#open(a:cmd, {'on_stderr': s:cadde})
endf " }}}

" Execute cmdline and redirect it's stderr to quickfix {{{
fun! qrun#errun(cmd)
    let winqf = 0 | let winterm = 0
    " Find a terminal or quickfix window
    for i in range(1, winnr('$'))
        let bt = getbufvar(winbufnr(i), '&bt')
        if bt == 'quickfix'
            let winqf = i
        elseif bt == 'terminal'
            let winterm = i
        endif
    endfo
    if !winterm
        if !winqf | copen | else
            call win_gotoid(win_getid(winqf))
        endif
        call vim#split()
    else
        call win_gotoid(win_getid(winterm))
        if !winqf
            call vim#split('copen')
            winc p
        endif
    endif

    let cmd = type(a:cmd) == v:t_list ? a:cmd : [a:cmd]
    let temp = tempname()
    cexpr ''
    call term#open(
        \ ['cmd.exe', '/Q', '/c', '@call', s:path . '\error.bat', temp] + cmd,
        \ {'on_exit': {j,d,s->vim#cfile(temp)}}
        \ )
    exe 'file' join(a:cmd)
endf " }}}

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

fun! qrun#search(pat)
    let result = ''
    let cp = getcurpos()[1:2]
    call cursor(nextnonblank(1), 1)
    if search(a:pat, 'c', line('.') + 10)
        let result = matchstr(getline('.'), a:pat)
    else
        call cursor(prevnonblank('$'), 1)
        call cursor('.', col('$'))
        if search(a:pat, 'bc', line('.') - 10)
            let result = matchstr(getline('.'), a:pat)
        endif
    endif
    call cursor(cp)
    return result
endf

fun! qrun#modeline()
    return qrun#search('qrun\.vim\%(@\w\+\)\?:\s*\zs.*')
endf

fun! qrun#gettype()
    if has_key(b:, 'qrun_type')
        return b:qrun_type
    endif
    let m = qrun#search('qrun\.vim@\zs\w\+\ze:')
    return empty(m) ? &ft: m
endf

fun! qrun#option(opt, ...)
    if !has_key(g:, 'qrun#options')
        let g:qrun#options = env#get('qrun_options', {})
    endif
    if a:0
        let g:qrun#options[a:opt] = a:1
        call env#set('qrun_options', g:qrun#options)
    else
        return has_key(g:qrun#options, a:opt) ? g:qrun#options[a:opt]: 0
    endif
endf
