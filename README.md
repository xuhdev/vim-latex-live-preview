# A Vim Plugin for Lively Previewing Your LaTeX Output

This plugin provides a live preview of the output PDF of your LaTeX file. The
display of the output PDF file will be updated lively as you type (just hold
the cursor and you will see the PDF file updated). Currently, vim-live-preview
is still in **alpha** stage and only support UNIX-like systems. Please let me
know if you have any suggestions. In the future, vim-live-preview should also
support other types of source file, such as HTML, markdown, etc.

## Installation

Before installation, you need to make sure your Vim version is later than 7.3,
and is compiled with `+python` feature. Then copy `plugin/livepreview.vim` to
`~/.vim/plugin`.

## Usage

Simply execute `:LPStartPreview` to launch the previewer. Then try to type in
Vim and you should see the live update.

