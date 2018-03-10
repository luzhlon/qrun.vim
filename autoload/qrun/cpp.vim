
let s:origin_path = $PATH
" Check the environtment {{{
if has('win32')
    let g:qrun#msvc#config = env#get('msvc')
    let s:current_arch = ''

    fun! qrun#cpp#switch_arch(arch)
        call assert_true(exists('g:qrun#msvc#config'))
        if s:current_arch != a:arch
            let conf = get(g:qrun#msvc#config, a:arch)
            if empty(conf)
                echom 'No this arch' arch | return
            endif
            let $INCLUDE = join(conf.INCLUDE, ';')
            let $LIB = join(conf.LIB, ';')
            let $PATH = s:merge_path(s:origin_path, conf.PATH)
            echo "qrun#cpp#compile: switch to " a:arch
            let s:current_arch = a:arch
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

    call qrun#cpp#switch_arch(has('win64') ? 'x64': 'x86')
endif " }}}

" Check compiler {{{
if has('win32') && executable('cl')
    fun! s:compile(s, o)
        let obj = fnamemodify(a:o, ':p:r')
        " return qrun#compile(['cl', a:s, '/Fe:', a:o, '/Fo:', obj, '/Fd:', obj, '/Zi'])
        return qrun#compile(['cl', a:s, '/Fe:', a:o, '/Fo:', obj])
    endf
    compiler msvc
elseif executable('g++')
    fun! s:compile(s, o)
        return qrun#compile(['g++', '-std=c++11', a:s, '-o', a:o])
    endf
    compiler gcc
elseif executable('clang++')
    fun! s:compile(s, o)
        return qrun#compile(['clang++', '-std=c++11', a:s, '-o', a:o])
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
    if exists('*s:compile')
        return s:compile(a:source, a:target)
    endif
    echom 'Can not found c++ compiler'
endf

fun! qrun#cpp#run()
    return qrun#exec(b:qrun)
endf
