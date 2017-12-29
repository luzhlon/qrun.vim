
" Check compiler {{{
if executable('g++')
    fun! s:compile(s, o)
        return qrun#compile(['g++', a:s, '-o', a:o])
    endf
    compiler gcc
elseif executable('clang++')
    fun! s:compile(s, o)
        return qrun#compile(['clang++', a:s, '-o', a:o])
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
