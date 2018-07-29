
if !executable('javac')
    echo 'javac not available'
    finish
endif

fun! qrun#java#init()
    let b:qrun = {'target': expand('%:r') . '.class'}
endf

fun! qrun#java#compile(source, target)
    compiler javac
    return qrun#compile(['javac', a:source])
endf

fun! qrun#java#run()
    let target = b:qrun.target
    let b:qrun.cmd = join(['java', fnamemodify(target, ':r')])
    return qrun#exec(b:qrun)
endf
