
" Check the environtment {{{
if has('win32')
    " Set the environtment variable INCLUDE LIB PATH
    fun! qrun#cpp#setenvs(...)
        let arch = a:0 ? a:1 : 0
        if empty(arch)
            let arch = has('win64') ? 'x64': 'x86'
        endif
        if exists('g:envs#vs')
            let conf = get(g:envs#vs, arch)
            if empty(conf)
                echo 'No this arch' arch | return
            endif
            let $INCLUDE = join(conf.INCLUDE, ';')
            let $LIB = join(conf.LIB, ';')
            let $PATH = s:merge_path($PATH, conf.PATH)
            echo "Loaded the environtments of visual studio"
        else
            echo 'Can not found environtments of visual studio'
            echo 'You can generate it by "gen_envs.py"'
        endif
    endf

    fun! s:merge_path(p1, p2)
        let deli = has('unix') ? ':': ';'
        let p1 = type(a:p1) == v:t_string ? split(a:p1, deli): a:p1
        let p2 = type(a:p2) == v:t_string ? split(a:p2, deli): a:p2
        let cache = {}
        for p in p1 | let cache[p] = 1 | endfo
        for p in p2
            if !has_key(cache, p)
                call add(p1, p)
            endif
        endfo
        return join(p1, deli)
    endf

    call qrun#cpp#setenvs()
endif " }}}

" Check compiler {{{
if has('win32') && executable('cl')
    fun! s:compile(s, o)
        let obj = fnamemodify(a:o, ':p:r')
        return qrun#compile(['cl', a:s, '/Fe:', a:o, '/Fo:', obj, '/Fd:', obj, '/Zi'])
    endf
    compiler msvc
elseif executable('g++')
    fun! s:compile(s, o)
        return qrun#compile(['g++', '-std=c++11', s, '-o', o])
    endf
    compiler gcc
elseif executable('clang++')
    fun! s:compile(s, o)
        return qrun#compile(['clang++', '-std=c++11', s, '-o', o])
    endf
    compiler gcc
else
    echom 'Can not found c++ compiler'
endif " }}}

fun! qrun#cpp#init()
    " Set the target
    let b:qrun = {'target': qrun#tempfile('.exe')}
endf

fun! qrun#cpp#compile(source, target)
    if !exists('*s:compile')
        echom 'Can not found c++ compiler'
        return
    endif
    return s:compile(a:source, a:target)
endf

fun! qrun#cpp#run()
    return qrun#exec(b:qrun)
endf
