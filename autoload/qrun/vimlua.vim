
lua << EOF
function _debug(file)
    local f, s, err
    local infos = {}

    f, err = loadfile(file)

    if f then
        local thread = coroutine.create(f)
        s, err = coroutine.resume(thread)
        if not s then
            err = err .. '\n' .. debug.traceback(thread)
        end
    end

    if err and #err ~= 0 then
        vim.api.nvim_command [[cexpr '']]
        _ = err
        vim.api.nvim_command [[cexpr luaeval('_')]]
        vim.api.nvim_command [[belowright copen]]
    end
end
EOF

fun! qrun#vimlua#init()
    let b:qrun = {}
endf

fun! qrun#vimlua#run()
    set efm=%f:%l:%m,@%f:%l:%m
    if has('nvim')
        lua _debug(vim.api.nvim_eval("@%"))
    else
        cexpr execute('lua %')
    endif
endf
