let s:session_files_list = {}
"let s:session_dir_list = {}
let s:session_pid = getpid()
"let s:hostname = hostname()
let s:session_storage_dir = $HOME . '/.yavsm_session_storage'



"function doit()
"    execute "silent keepjumps hide edit[LoadSession]"
"    call s:DisplayBufferList()
"endfunction
"
"" DisplayBufferList {{{2
"function! s:DisplayBufferList()
"    " Do not set bufhidden since it wipes out the data if we switch away from
"    " the buffer using CTRL-^.
"    setlocal buftype=nofile
"    setlocal modifiable
"    setlocal noswapfile
"    setlocal nowrap
"
"    call s:SetupSyntax()
"    call s:MapKeys()
"
"    " Wipe out any existing lines in case BufExplorer buffer exists and the
"    " user had changed any global settings that might reduce the number of
"    " lines needed in the buffer.
"    silent keepjumps 1,$d _
"
"    call setline(1, s:CreateHelp())
"    call s:BuildBufferList()
"    call cursor(s:firstBufferLine, 1)
"
"    if !g:bufExplorerResize
"        normal! zz
"    endif
"
"    setlocal nomodifiable
"endfunction


func! yavsm#generate_display_entries()
    let sessions_files = split(globpath(s:session_storage_dir, '*.sss'), '\n')
    let cur_timestamp = localtime()
    let timestamp_map = {}
    for file_name in sessions_files
        let s_file_path = s:session_storage_dir . '/' . file_name
        let file_timestamp = getftime(s_file_path)
        " TODO implement removal of old files
        let hr_file_time = strftime("%Y %b %d %X")
        let entry = []
        call add(entry, hr_file_time)
        call add(entry, file_name)
        let session_files = readfile(s_file_path)
        for session_file in sessions_files
            let session_file_basename = fnamemodify(session_file, ":t")
            call add(entry, session_file)
        endfor
        timestamp_map[file_timestamp] = entry
    endfor
    let timestamps = reverse(sort(keys(timestamp_map), 'n'))
    let result = []
    for timestamp in timestamps
        call add(result, timestamp_map[timestamp])
    endfor
    return result
endfunc


func! yavsm#show_sessions()
    let display_entries = yavsm#generate_display_entries()
endfunc


func! yavsm#save_session_state()
    let lines = keys(s:session_files_list)
    let dst_path = s:session_storage_dir . '/' . s:session_pid . '.sss'
    call writefile(lines, dst_path)
endfunc


func! yavsm#handle_buffer_enter()
    let cur_timestamp = localtime()
    let hr_time = strftime("%Y %b %d %X")
    let buf_path = resolve(expand("%:p"))
    if !has_key(s:session_files_list, buf_path)
        let s:session_files_list[buf_path] = 1
        yavsm#save_session_state()
    endif
endfunc


autocmd BufEnter * call yavsm#handle_buffer_enter()
command! ShowSessions call yavsm#show_sessions()
command! SaveSessionStateManual call yavsm#save_session_state()
