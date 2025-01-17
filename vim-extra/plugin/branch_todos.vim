""
" Parses the diff against the upstream branch (`@{u}`) and adds all new (or
" changed) lines which match "todo" to the quick fix list.
command! FindBranchTodos call <SID>FindBranchTodos()

function s:FindBranchTodos() abort
  let l:find_root_cmd = 'git rev-parse --show-toplevel'
  let l:git_root = shellescape(systemlist(l:find_root_cmd)[0].'/')
  let l:upstream =
      \ system( 'git rev-parse --symbolic-full-name @{u} 2&>/dev/null')
  if l:upstream =~# '^refs/remotes/'
    let l:upstream = trim(system('git default-branch'))
  endif
  let l:diff =
      \ system('git diff '.shellescape(l:upstream).' --dst-prefix='.l:git_root)
  let l:items = s:ParseAddedTodos(split(l:diff, "\n"))
  call setqflist(l:items)
  copen
endfunction

""
" Parse a unified diff format output and create quick fix items for lines
" matching "todo". Tracks the file name and line numbers as indicated by the
" diff section headings.
function! s:ParseAddedTodos(lines) abort
  let l:items = []
  let l:current_file = ''
  let l:current_line = 0
  for l:line in a:lines
    if l:line =~# '^+++'
      let l:current_file = split(l:line)[1]
    elseif l:line =~# '^@@'
      " `@@ -xx,xx +LL,xx @@` -> (LL - 1)
      let l:current_line = split(split(l:line)[2],',')[0][1:] - 1
    elseif l:line =~# '^ '
      let l:current_line += 1
    elseif l:line =~# '^+'
      let l:current_line += 1
      if l:line =~? 'todo'
        call add(l:items, {
            \ 'lnum': l:current_line,
            \ 'text': l:line[1:],
            \ 'filename': fnamemodify(l:current_file, ':.')
            \})
      endif
    endif
  endfor
  return l:items
endfunction
