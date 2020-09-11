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
    echo "Already loaded"
    finish
endif
let g:loaded_vim_live_preview = 1

" Check mkdir feature
if (!exists("*mkdir"))
    echohl ErrorMsg
    echo 'vim-latex-live-preview: mkdir functionality required'
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
    echo 'vim-latex-live-preview: python required'
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

    " This Pattern Matching will FAIL for multiline biblatex declarations,
    " in which case the `g:livepreview_use_biber` setting must be respected.
    let l:general_pattern = '^\\usepackage\[.*\]{biblatex}'
    let l:specific_pattern = 'backend=bibtex'
    let l:position = search(l:general_pattern, 'cw')
    if ( l:position != 0 )
        let l:matches = matchstr(getline(l:position), specific_pattern)
        if ( l:matches == '' )
            " expect s:use_biber=1
            if ( s:use_biber == 0 )
                let s:use_biber = 1
                echohl ErrorMsg
                echom "g:livepreview_use_biber not set or does not match `biblatex` usage in your document. Overridden!"
                echohl None
            endif
        else
            " expect s:use_biber=0
            if ( s:use_biber == 1 )
                let s:use_biber = 0
                echohl ErrorMsg
                echom "g:livepreview_use_biber is set but `biblatex` is explicitly using `bibtex`. Overridden!"
                echohl None
            endif
        endif
    else
        " expect s:use_biber=0
        " `biblatex` is not being used, this usually means we
        " are using `bibtex`
        " However, it is not a universal rule, so we do nothing.
    endif

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
                \       'TEXINPUTS=' . s:static_texinputs
                \                    . ':' . l:tmp_root_dir
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

        if s:use_biber
            let s:bibexec = 'biber --input-directory=' . l:tmp_root_dir . '--output-directory=' . l:tmp_root_dir . ' ' . l:root_file
        else
            " The alternative to this pushing and popping is to write
            " temporary files to a `.tmp` folder in the current directory and
            " then `mv` them to `/tmp` and delete the `.tmp` directory.
            let s:bibexec = 'pushd ' . l:tmp_root_dir . ' && bibtex *.aux' . ' && popd'
        endif

        let b:livepreview_buf_data['run_bib_cmd'] =
                \       'env ' .
                \               'TEXMFOUTPUT=' . l:tmp_root_dir . ' ' .
                \               'TEXINPUTS=' . s:static_texinputs
                \                            . ':' . l:tmp_root_dir
                \                            . ':' . b:livepreview_buf_data['root_dir']
                \                            . ': ' .
                \ ' && ' . s:bibexec

        silent call system(b:livepreview_buf_data['run_bib_cmd'])
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

    function! s:ValidateExecutables( context, executables )
        let l:user_set = get(g:, a:context, '')
        if l:user_set != ''
            return l:user_set
        endif
        for possible_engine in a:executables
            if executable(possible_engine)
                return possible_engine
            endif
        endfor
        echohl ErrorMsg
        echo printf("vim-latex-live-preview: The defaults for % are not executable.", a:context)
        echohl None
        throw "End execution"
    endfunction

    " Get the tex engine
    let s:engine = s:ValidateExecutables('livepreview_engine', ['pdflatex', 'xelatex'])

    " Get the previewer
    let s:previewer = s:ValidateExecutables('livepreview_previewer', ['evince', 'okular'])

     " Initialize texinputs directory list to environment variable TEXINPUTS if g:livepreview_texinputs is not set
    let s:static_texinputs = get(g:, 'livepreview_texinputs', $TEXINPUTS)

    " Select bibliography executable
    let s:use_biber = get(g:, 'livepreview_use_biber', 0)

    return 0
endfunction

try
    let s:init_msg = s:Initialize()
catch
    finish
endtry

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
