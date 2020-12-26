let s:session_files_list = {}
let s:session_id = getpid()
let s:session_storage_dir = $HOME . '/.yavsm_session_storage'
let s:enable_yavsm_buf_trigger = 1


func! s:setup_yavsm_syntax()
    syn match yavsm_file   "# *[0-9][0-9]*\.sss *#"
    syn match yavsm_date   "^[^#]*"
    hi def link yavsm_date Comment
    hi def link yavsm_file String
endfunc


func! yavsm#save_session_state()
    let lines = keys(s:session_files_list)
    let filtered_lines = []
    for line in lines
        if len(line) && filereadable(line)
            call add(filtered_lines, line)
        endif
    endfor
    let dst_path = s:session_storage_dir . '/' . s:session_id . '.sss'
    call writefile(filtered_lines, dst_path)
endfunc


func! s:select_yavsm_session()
    let selected_record_line = getline('.')
    let session_ctx_file_name = split(selected_record_line, '#')[1]
    let session_ctx_file_path = s:session_storage_dir . '/' . session_ctx_file_name
    let file_components = split(session_ctx_file_name, '\.')
    if len(file_components) != 2 || file_components[1] != 'sss'
        return
    endif
    let s:session_id = file_components[0]
    let session_files = readfile(session_ctx_file_path)
    let s:enable_yavsm_buf_trigger = 0
    for session_file in session_files
        if len(session_file) && !has_key(s:session_files_list, session_file) && filereadable(session_file)
            execute "e " . fnameescape(session_file)
            let s:session_files_list[session_file] = 1
        endif
    endfor
    let s:enable_yavsm_buf_trigger = 1
    call yavsm#save_session_state()
endfunc


func! yavsm#generate_display_entries()
    let session_ctx_files = split(globpath(s:session_storage_dir, '*.sss'), '\n')
    let cur_timestamp = localtime()
    let timestamp_map = {}
    for s_file_path in session_ctx_files
        let file_timestamp = getftime(s_file_path)
        if cur_timestamp - file_timestamp > 3600 * 24 * 30
            call delete(s_file_path)
            continue
        endif
        let hr_file_time = strftime("%Y %b %d %X", file_timestamp)
        let entry = [hr_file_time . ' #' . fnamemodify(s_file_path, ":t") . '# ']
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
    nnoremap <script> <silent> <nowait> <buffer> <CR> :call <SID>select_yavsm_session()<CR>

    call setline(1, display_entries)

    call cursor(1, 1)
    setlocal nomodifiable
endfunc


func! yavsm#handle_buffer_enter()
    if !s:enable_yavsm_buf_trigger
        return
    endif
    let buf_path = resolve(expand("%:p"))
    if len(buf_path) && !has_key(s:session_files_list, buf_path) && filereadable(buf_path)
        let s:session_files_list[buf_path] = 1
        call yavsm#save_session_state()
    endif
endfunc


autocmd BufEnter * call yavsm#handle_buffer_enter()
command! ShowSessions call yavsm#show_sessions()
command! SaveSessionStateManual call yavsm#save_session_state()
