let s:session_files_list = {}
let s:session_pid = getpid()
let s:session_storage_dir = $HOME . '/.yavsm_session_storage'


func! s:setup_yavsm_syntax()
    syn match yavsm_file   "# [0-9][0-9]*\.sss #"
    syn match yavsm_date   "^[^#]*"
    hi def link yavsm_date Comment
    hi def link yavsm_file String
endfunc


func! yavsm#generate_display_entries()
    let session_ctx_files = split(globpath(s:session_storage_dir, '*.sss'), '\n')
    let cur_timestamp = localtime()
    let timestamp_map = {}
    for s_file_path in session_ctx_files
        let file_timestamp = getftime(s_file_path)
        " TODO implement removal of old files
        let hr_file_time = strftime("%Y %b %d %X", file_timestamp)
        let entry = [hr_file_time . ' # ' . fnamemodify(s_file_path, ":t") . ' # ']
        let session_files = readfile(s_file_path)
        for session_file in session_files
            let session_file_basename = fnamemodify(session_file, ":t")
            call add(entry, session_file_basename)
        endfor
        let timestamp_map[file_timestamp] = join(entry, ' ')
    endfor
    let timestamps = reverse(sort(keys(timestamp_map), 'N'))
    let result = []
    for timestamp in timestamps
        call add(result, timestamp_map[timestamp])
    endfor
    return result
endfunc


func! yavsm#show_sessions()
    let display_entries = yavsm#generate_display_entries()
    execute "silent keepjumps hide edit[LoadSession]"
    setlocal buftype=nofile
    setlocal modifiable
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal foldcolumn=0
    setlocal nofoldenable
    setlocal cursorline
    setlocal nospell
    setlocal nobuflisted
    setlocal filetype=yavsm

    call s:setup_yavsm_syntax()

    call setline(1, display_entries)

    call cursor(1, 1)
    setlocal nomodifiable
endfunc


func! yavsm#save_session_state()
    let lines = keys(s:session_files_list)
    let filtered_lines = []
    for line in lines
        if len(line) && filereadable(line)
            call add(filtered_lines, line)
        endif
    endfor
    let dst_path = s:session_storage_dir . '/' . s:session_pid . '.sss'
    call writefile(filtered_lines, dst_path)
endfunc


func! yavsm#handle_buffer_enter()
    let cur_timestamp = localtime()
    let hr_time = strftime("%Y %b %d %X")
    let buf_path = resolve(expand("%:p"))
    if len(buf_path) && !has_key(s:session_files_list, buf_path) && filereadable(buf_path)
        let s:session_files_list[buf_path] = 1
        call yavsm#save_session_state()
    endif
endfunc


autocmd BufEnter * call yavsm#handle_buffer_enter()
command! ShowSessions call yavsm#show_sessions()
command! SaveSessionStateManual call yavsm#save_session_state()
