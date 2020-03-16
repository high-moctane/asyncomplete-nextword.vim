augroup asyncomplete#sources#nextword#augroup
    autocmd!
    autocmd VimLeave * s:stop_nextword()
augroup END

function! asyncomplete#sources#nextword#get_source_options(opt)
    return a:opt
endfunction

function! asyncomplete#sources#nextword#completor(opt, ctx)
    if s:nextword_job <= 0
        return
    endif

    let l:typed = s:get_typed_string(a:ctx)
    let s:ctx = a:ctx
    call async#job#send(s:nextword_job, l:typed . "\n")
endfunction

function! s:get_typed_string(ctx)
    let l:first_lnum = max([1, a:ctx['lnum']-4])
    let l:cur_lnum = a:ctx['lnum']

    let l:lines = []
    for l:lnum in range(l:first_lnum, l:cur_lnum)
        call add(l:lines, getline(l:lnum))
    endfor

    return join(l:lines, ' ')
endfunction

function! s:on_event(job_id, data, event)
    if a:event != 'stdout'
        return
    endif

    let l:startcol = strridx(s:ctx['typed'], " ") + 2
    let l:candidates = split(a:data[0], " ")
    let l:items = s:generate_items(l:candidates)
    call asyncomplete#log(l:startcol)
    call asyncomplete#complete("nextword", s:ctx, l:startcol, l:items)
endfunction

function! s:generate_items(candidates)
    return map(a:candidates, '{"word": v:val, "kind": "[Nextword]"}')
endfunction

function! s:stop_nextword()
    call async#job#stop(s:nextword_job)
endfunction

let s:nextword_job = async#job#start(['nextword', '-c', '10000'], {'on_stdout': function('s:on_event')})
let s:ctx = {}
