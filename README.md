# A Vim Plugin for Lively Previewing LaTeX PDF Output

This plugin provides a live preview of the output PDF of your LaTeX file. The
display of the output PDF file will be updated lively as you type (just hold
the cursor and you will see the PDF file updated). Currently,
vim-latex-live-preview is still in **alpha** stage and only support UNIX-like
systems. Please let me know if you have any suggestions.

## Installation

Before installation, you need to make sure your Vim version is later than 7.3,
and is compiled with `+python` feature. Also, you need to have [evince][] or
[okular][] installed. Then copy `plugin/latexlivepreview.vim` to
`~/.vim/plugin`.

## Usage

Simply execute `:LLPStartPreview` to launch the previewer. Then try to type in
Vim and you should see the live update.

## Screenshot

![](https://github.com/xuhdev/vim-latex-live-preview/raw/master/screenshots/screenshot.gif)

<!--
The screenshot is at ./screenshots/screenshot.gif
-->

[evince]: http://projects.gnome.org/evince/
[okular]: http://okular.kde.org/
