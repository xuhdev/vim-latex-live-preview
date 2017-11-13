A Vim Plugin for Lively Previewing LaTeX PDF Output
===================================================

This plugin provides a live preview of the output PDF of your LaTeX file. The
display of the output PDF file will be updated lively as you type (just hold
the cursor and you will see the PDF file updated). Currently,
vim-latex-live-preview only support UNIX-like systems. [Please let me know if
you have any suggestions.](.github/CONTRIBUTING.md)

![Screenshot with Evince](misc/screenshot-evince.gif)

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Known Issues](#known-issues)
- [Contributing](#contributing)
- [Release History](#release-history)

# Installation

Before installing, you need to make sure your Vim version is later than 7.3,
and is [compiled](https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source) with `+python` feature.

### [vim-plug](https://github.com/junegunn/vim-plug)

Add the plugin in the vim-plug section of your `~/.vimrc`:

```vim
call plug#begin('~/.vim/plugged')
[...]
" A Vim Plugin for Lively Previewing LaTeX PDF Output
Plug 'xuhdev/vim-latex-live-preview', { 'for': 'tex' }
[...]
call plug#end()
```

Then reload the config and install the new plugin. Run inside `vim`:

```vim
:so ~/.vimrc
:PlugInstall
```

### [Vundle](https://github.com/VundleVim/Vundle.vim)

Add the plugin in the Vundle section of your `~/.vimrc`:

```vim
call vundle#begin()
[...]
" A Vim Plugin for Lively Previewing LaTeX PDF Output
Plugin 'xuhdev/vim-latex-live-preview'
[...]
call vundle#end()
```

Then reload the config and install the new plugin. Run inside `vim`:

```vim
:so ~/.vimrc
:PluginInstall
```

### Manually

Copy `plugin/latexlivepreview.vim` to `~/.vim/plugin`.

# Usage


Simply execute `:LLPStartPreview` to launch the previewer. Then try to type in
Vim and you should see the live update. The updating time could be set by Vim's
['updatetime'][] option. If your pdf viewer crashes when updates happen, you can
try to set 'updatetime' to a higher value to make it update less frequently. The
suggested value of 'updatetime' is `1000`.

If the root file is not the file you are currently editing, you can specify it
by executing `:LLPStartPreview <root-filename>` or executing `:LLPStartPreview`
with the following declaration in the first line of your source file:

```latex
% !TEX root = <root-filename>
```

The path to the root file can be an absolute path or a relative path, in which
case it is **relative to the parent directory of the current file**.

:warning: if `<root-filename>` contains special characters (such as space), they
must be escaped manually.

# Configuration


### PDF Viewer

By default, you need to have [evince][] or [okular][] installed as pdf viewers.
But you can specify your own viewer by setting `g:livepreview_previewer`
option in your `.vimrc`:

```vim
let g:livepreview_previewer = 'your_viewer'
```

Please note that not every pdf viewer could work with this plugin. Currently
evince and okular are known to work well. You can find a list of known working
pdf viewers [here](https://github.com/xuhdev/vim-latex-live-preview/wiki/Known-Working-PDF-Viewers).

### TeX Engine

`LLP` uses `pdflatex` as default engine to output a PDF to be previewed. It
fallbacks to `xelatex` if `pdflatex` is not present. These defaults can be
overridden by setting `g:livepreview_engine` variable:

```vim
let g:livepreview_engine = 'your_engine' . ' [options]'
```

# Known Issues


### Swap Error

An error `E768: Swap file exists` may occur. See
[issue #7](https://github.com/xuhdev/vim-latex-live-preview/issues/7) to avoid
swap filename collision.

### Project Tree

Currently, root file must be in the same directory or upper in the project tree
(otherwise, one has to save file to update the preview).

### E492: Not an editor command: LLPStartPreview
Check Issue [#12](https://github.com/xuhdev/vim-latex-live-preview/issues/12), provided the plugin is correctly installed, this is likely a **Python** issue.

### Python-related Issues 

* 2.7 vs 3.5: 
This is an ongoing issue: [#12](https://github.com/xuhdev/vim-latex-live-preview/issues/12)

* python/dyn
See Issue [#24](https://github.com/xuhdev/vim-latex-live-preview/issues/24), currently ```vim-latex-live-preview``` does not support ```python/dyn``` and Vim must be recompiled with Python support. 

## Release History
### Added

- [[`e33ee6c`](https://github.com/xuhdev/vim-latex-live-preview/commit/e33ee6c)] - Support multiple files project [#26](https://github.com/xuhdev/vim-latex-live-preview/pull/26)
- [[`bf5259b`](https://github.com/xuhdev/vim-latex-live-preview/commit/bf5259b)] - Support bibliography [#3](https://github.com/xuhdev/vim-latex-live-preview/pull/3)

### Fixed

- [[`cbf5a1d`](https://github.com/xuhdev/vim-latex-live-preview/commit/cbf5a1d)] - Support paths and filenames containing spaces [#35](https://github.com/xuhdev/vim-latex-live-preview/issues/35)
- [[`8cdc672`](https://github.com/xuhdev/vim-latex-live-preview/commit/8cdc672)] - Early exit on compilation failure [#25](https://github.com/xuhdev/vim-latex-live-preview/pull/25)

0.1.0 (Apr 16, 2013)
- First release


## Contributing

1. Fork it (<https://github.com/yourname/yourproject/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request









<!--
The screenshot is at ./misc/screenshot-evince.gif
-->

['updatetime']: http://vimdoc.sourceforge.net/htmldoc/options.html#%27updatetime%27
[evince]: http://projects.gnome.org/evince/
[okular]: http://okular.kde.org/
