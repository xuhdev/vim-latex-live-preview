" Copyright (C) 2012 Hong Xu

" This file is part of vim-live-preview.

" vim-live-preview is free software: you can redistribute it and/or modify it
" under the terms of the GNU General Public License as published by the Free
" Software Foundation, either version 3 of the License, or (at your option)
" any later version.

" vim-live-preview is distributed in the hope that it will be useful, but
" WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
" or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
" more details.

" You should have received a copy of the GNU General Public License along with
" vim-live-preview.  If not, see <http://www.gnu.org/licenses/>.


if v:version < 700
    finish
endif

" check whether this script is already loaded
if exists("g:loaded_vim_live_preview")
    finish
endif
let g:loaded_vim_live_preview = 1

" this plugin requires +python feature
if !has('python')
    finish
endif

let s:saved_cpo = &cpo
set cpo&vim

let s:previewer = ''

" Run a shell command in background
function! s:RunInBackground(cmd)

python << EEOOFF

try:
    subprocess.Popen(
            vim.eval('a:cmd'),
            shell = True,
            universal_newlines = True,
            stdout=open(os.devnull, 'w'), stderr=subprocess.STDOUT)

except:
    pass
EEOOFF
endfunction

function! s:Compile()

    if !exists('b:livepreview_buf_data') ||
                \ has_key(b:livepreview_buf_data, 'preview_running') == 0 ||
                \ b:livepreview_buf_data['preview_running'] == 0
        return
    endif

    lcd %:p:h

    silent exec 'write! ' . b:livepreview_buf_data['tmp_src_file']

    call s:RunInBackground(
                \ 'pdflatex -shell-escape -interaction=nonstopmode -output-directory=' .
                \ b:livepreview_buf_data['tmp_dir'] . ' ' .
                \ b:livepreview_buf_data['tmp_src_file'])

    if b:livepreview_buf_data['has_bibliography']
        " ToDo: Make the following work in Windows
        call system('cd ' .  b:livepreview_buf_data['tmp_dir'] .
                    \ ' && bibtex *.aux')
    endif

    lcd -
endfunction

function! s:StartPreview()
    lcd %:p:h
    
    let b:livepreview_buf_data = {}

    " Create a temp directory for current buffer
    python << EEOOFF
vim.command("let b:livepreview_buf_data['tmp_dir'] = '" +
        tempfile.mkdtemp() + "'")
EEOOFF

    let b:livepreview_buf_data['tmp_src_file'] =
                \ b:livepreview_buf_data['tmp_dir'] . '/' .
                \ fnameescape(expand('%:r')) . '.' . expand('%:e')

    silent exec 'write! ' . b:livepreview_buf_data['tmp_src_file']

    let l:tmp_out_file = b:livepreview_buf_data['tmp_dir'] . '/' .
                \ fnameescape(expand('%:r')) . '.pdf'

    silent call system('pdflatex -shell-escape -interaction=nonstopmode -output-directory=' .
                \ b:livepreview_buf_data['tmp_dir'] . ' ' .
                \ b:livepreview_buf_data['tmp_src_file'])
    if v:shell_error != 0
        echo 'Failed to compile'
    endif

    " Enable compilation of bibliography:
    let l:bib_files = split( glob( expand( '%:h' ) . '/**/*bib' ) )
    let b:livepreview_buf_data['has_bibliography'] = 0
    if len( l:bib_files ) > 0
        let b:livepreview_buf_data['has_bibliography'] = 1
        for bib_file in l:bib_files
            let bib_fn = fnamemodify(bib_file, ':t')
            call writefile(readfile(bib_file),
                        \ b:livepreview_buf_data['tmp_dir'] . '/' . bib_fn )
        endfor
        " ToDo: Make the following work in Windows
        silent call system('cd ' . b:livepreview_buf_data['tmp_dir'] .
                    \ ' && bibtex *.aux')
        " Bibtex requires multiple latex compilations:
        silent call system(
                    \ 'pdflatex -shell-escape -interaction=nonstopmode -output-directory=' .
                    \ b:livepreview_buf_data['tmp_dir'] . ' ' .
                    \ b:livepreview_buf_data['tmp_src_file'])
    endif
    if v:shell_error != 0
        echo 'Failed to compile bibliography'
    endif

    call s:RunInBackground(s:previewer . ' ' . l:tmp_out_file)

    lcd -
    
    let b:livepreview_buf_data['preview_running'] = 1
endfunction

" Initialization code
function! s:Initialize()
    let l:ret = 0
    python << EEOOFF
try:
    import vim
    import tempfile
    import subprocess
    import os
except:
    vim.command('let l:ret = 1')
EEOOFF

    if l:ret != 0
        return 'Python initialization failed.'
    endif

    " Get the previewer
    if exists('g:livepreview_previewer')
        let s:previewer = g:livepreview_previewer
    else
        for possible_previewer in [
                    \ 'evince',
                    \ 'okular']
            if executable(possible_previewer)
                let s:previewer = possible_previewer
                break
            endif
        endfor
    endif

    return 0
endfunction


let s:init_msg = s:Initialize()

if type(s:init_msg) == type('')
    echohl ErrorMsg
    echo 'vim-live-preview: ' . s:init_msg
    echohl None
endif

unlet! s:init_msg

command! LLPStartPreview call s:StartPreview()

autocmd CursorHold,CursorHoldI,BufWritePost *.tex call s:Compile()

let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim703: cc=80
" vim:fdm=marker et ts=4 tw=78 sw=4
