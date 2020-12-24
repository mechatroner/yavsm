let s:session_files_list = {}

func! yavsm#handle_buffer_enter()
endfunc


autocmd BufEnter * call yavsm#handle_buffer_enter()
