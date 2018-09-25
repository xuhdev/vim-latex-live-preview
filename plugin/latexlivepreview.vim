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

" Check whether this script is already loaded
if exists("g:loaded_vim_live_preview")
    finish
endif
let g:loaded_vim_live_preview = 1

" Check mkdir feature
if (!exists("*mkdir"))
    echohl ErrorMsg
    echo 'vim-llp: mkdir required'
    echohl None
    finish
endif

" Setup python
if (has('python3'))
    let s:py_exe = 'python3'
elseif (has('python'))
    let s:py_exe = 'python'
else
    echohl ErrorMsg
    echo 'vim-llp: python required'
    echohl None
    finish
endif

let s:saved_cpo = &cpo
set cpo&vim

let s:previewer = ''

" Run a shell command in background
function! s:RunInBackground(cmd)

execute s:py_exe "<< EEOOFF"

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
                \ has_key(b:livepreview_buf_data, 'preview_running') == 0
        return
    endif

    " Change directory to handle properly sourced files with \input and bib
    " TODO: get rid of lcd
    execute 'lcd ' . b:livepreview_buf_data['root_dir']

    " Write the current buffer in a temporary file
    silent exec 'write! ' . b:livepreview_buf_data['tmp_src_file']

    call s:RunInBackground(b:livepreview_buf_data['run_cmd'])

    lcd -
endfunction

function! s:StartPreview(...)
    let b:livepreview_buf_data = {}

    let b:livepreview_buf_data['py_exe'] = s:py_exe

    " Create a temp directory for current buffer
    execute s:py_exe "<< EEOOFF"
vim.command("let b:livepreview_buf_data['tmp_dir'] = '" +
        tempfile.mkdtemp(prefix="vim-latex-live-preview-") + "'")
EEOOFF

    let b:livepreview_buf_data['tmp_src_file'] =
                \ b:livepreview_buf_data['tmp_dir'] .
                \ expand('%:p:r')

    " Guess the root file which will be compiled, using first the argument
    " passed, then the first line declaration of the source file and
    " eventually fallback to the current file.
    " TODO: emulate -parse-first-line properly
    let l:root_line = substitute(getline(1),
                \ '\v^\s*\%\s*!TEX\s*root\s*\=\s*(.*)\s*$',
                \ '\1', '')
    if (a:0 > 0)
        let l:root_file = fnamemodify(a:1, ':p')
    elseif (l:root_line != getline(1) && strlen(l:root_line) > 0)                       " TODO: existence of `% !TEX` declaration condition must be cleaned...
        let l:root_file = fnamemodify(l:root_line, ':p')
    else
        let l:root_file = b:livepreview_buf_data['tmp_src_file']
    endif

    " Hack for complex project trees: recreate the tree in tmp_dir
    " Build tree for tmp_src_file (copy of the current buffer)
    let l:tmp_src_dir = fnamemodify(b:livepreview_buf_data['tmp_src_file'], ':p:h')
    if (!isdirectory(l:tmp_src_dir))
        silent call mkdir(l:tmp_src_dir, 'p')
    endif
    " Build tree for root_file (main tex file, which might be tmp_src_file,
    " ie. the current file)
    if (l:root_file == b:livepreview_buf_data['tmp_src_file'])                          " if root file is the current file
        let l:tmp_root_dir = l:tmp_src_dir
    else
        let l:tmp_root_dir = b:livepreview_buf_data['tmp_dir'] . fnamemodify(l:root_file, ':p:h')
        if (!isdirectory(l:tmp_root_dir))
            silent call mkdir(l:tmp_root_dir, 'p')
        endif
    endif

    " Escape pathnames
    let l:root_file = fnameescape(l:root_file)
    let l:tmp_root_dir = fnameescape(l:tmp_root_dir)
    let b:livepreview_buf_data['tmp_dir'] = fnameescape(b:livepreview_buf_data['tmp_dir'])
    let b:livepreview_buf_data['tmp_src_file'] = fnameescape(b:livepreview_buf_data['tmp_src_file'])

    " Change directory to handle properly sourced files with \input and bib
    " TODO: get rid of lcd
    if (l:root_file == b:livepreview_buf_data['tmp_src_file'])                          " if root file is the current file
        let b:livepreview_buf_data['root_dir'] = fnameescape(expand('%:p:h'))
    else
        let b:livepreview_buf_data['root_dir'] = fnamemodify(l:root_file, ':p:h')
    endif
    execute 'lcd ' . b:livepreview_buf_data['root_dir']

    " Write the current buffer in a temporary file
    silent exec 'write! ' . b:livepreview_buf_data['tmp_src_file']

    let l:tmp_out_file = l:tmp_root_dir . '/' .
                \ fnamemodify(l:root_file, ':t:r') . '.pdf'

    let b:livepreview_buf_data['run_cmd'] =
                \ 'env ' .
                \       'TEXMFOUTPUT=' . l:tmp_root_dir . ' ' .
                \       'TEXINPUTS=' . l:tmp_root_dir
                \                    . ':' . b:livepreview_buf_data['root_dir']
                \                    . ': ' .
                \ s:engine . ' ' .
                \       '-shell-escape ' .
                \       '-interaction=nonstopmode ' .
                \       '-output-directory=' . l:tmp_root_dir . ' ' .
                \       l:root_file
                " lcd can be avoided thanks to root_dir in TEXINPUTS

    silent call system(b:livepreview_buf_data['run_cmd'])
    if v:shell_error != 0
        echo 'Failed to compile'
        lcd -
        return
    endif

    " Enable compilation of bibliography:
    let l:bib_files = split(glob(b:livepreview_buf_data['root_dir'] . '/**/*.bib'))     " TODO: fails if unused bibfiles
    if len(l:bib_files) > 0
        for bib_file in l:bib_files
            let bib_fn = fnamemodify(bib_file, ':t')
            call writefile(readfile(bib_file),
                        \ l:tmp_root_dir . '/' . bib_fn)                                " TODO: may fail if same bibfile names in different dirs
        endfor

        " Update compile command with bibliography
        let b:livepreview_buf_data['run_cmd'] =
                \       'env ' .
                \               'TEXMFOUTPUT=' . l:tmp_root_dir . ' ' .
                \               'TEXINPUTS=' . l:tmp_root_dir
                \                            . ':' . b:livepreview_buf_data['root_dir']
                \                            . ': ' .
                \       'bibtex ' . l:tmp_root_dir . '/*.aux' .
                \ ' && ' .
                \       b:livepreview_buf_data['run_cmd']

        silent call system(b:livepreview_buf_data['run_cmd'])
    endif
    if v:shell_error != 0
        echo 'Failed to compile bibliography'
        lcd -
        return
    endif

    call s:RunInBackground(s:previewer . ' ' . l:tmp_out_file)

    lcd -

    let b:livepreview_buf_data['preview_running'] = 1
endfunction

" Initialization code
function! s:Initialize()
    let l:ret = 0
    execute s:py_exe "<< EEOOFF"
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

    " Get the tex engine
    if exists('g:livepreview_engine')
        let s:engine = g:livepreview_engine
    else
        for possible_engine in ['pdflatex', 'xelatex']
            if executable(possible_engine)
                let s:engine = possible_engine
                break
            endif
        endfor
    endif

    " Get the previewer
    if exists('g:livepreview_previewer')
        let s:previewer = g:livepreview_previewer
    else
        for possible_previewer in ['evince', 'okular']
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

command! -nargs=* LLPStartPreview call s:StartPreview(<f-args>)

if get(g:, 'livepreview_cursorhold_recompile', 1)
    autocmd CursorHold,CursorHoldI,BufWritePost * call s:Compile()
else
    autocmd BufWritePost * call s:Compile()
endif

let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim703: cc=80
" vim:fdm=marker et ts=4 tw=78 sw=4
