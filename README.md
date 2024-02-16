---
title: SPEC
description: specification for lunatikz
authors: Daniel
categories: spec
cpreated: 2024-02-05T17:13:44+0530
updated: 2024-02-16T06:01:37+0530
version: 1.1.1
---

# LunaTikZ - A tikz picture builder


LunaTikZ is a tikzpicture builder written in LUA. It reads the input file
and its included files, takes every arguments to `\includegraphics` macro
and tries to build that pdf file from the corresponding tex file in the
corresponding `tikzpics` directory. In order to use `lunatikz`, the project
needs to structured specifically.

# LunaTikZ project directory structure

At the root of every lunatikz project directory, there will be a
`.lunatikz` directory. This is where lunatikz will store project
related information, config, and caches. These are the filea lunatikz
stores in the `.lunatikz/`:

| Files | Description|
|---|---|
|`config`|Stores the local config of the lunatikz directory|
|`dep_cache`|Cache file that lunatikz uses to store the dependancy tree pics|
|`build_entry`|Stores the build entries for each of the directories|
|`ldep_list`|List of local dependencies, ie name and relative path from root directory|

# Usage

## init subcommand


`init` initializes a lunatikz directory. `lunatikz init [dir]` will
initialize a lunatikz directory in the `dir`. `dir` is optional and can be
more than one. if nothing is given, lunatikz will initialize the current
directory as a lunatikz directory. If ran inside another lunatikz directory,
ie, current directory or `dir` has a `.lunatikz` directory lunatikz will
refuse to initialize the directory as a lunatikz directory (because it's
already one). Otherwise, lunatikz will initializes the dir as a lunatikz
directory.

If a non existant `dir` was given, lunatikz will create that directory and
initializes it as a lunatikz directory.



## config subcommand


lunatikz `config` will help the user to set configuration on a per project
basis, or a global wide basis (NOTE: global config is not yet implemented).
The global `config` will be read everytime the user invokes lunatikz then
lunatikz will read per project `config` and merges it with global `config`.
The per project `config` can override the global `config`. (NOTE: since
global config is not implemented yet, no merging will happens)


### configurable parameters



#### pics.directory (default: tikzpics)


The directory where pics are stored.


#### pics.skip (default: false)


If true, skips reading all the files exists in `pics.directory` instead
reads the pics list from `.lunatikz/gdep_list`, and the user can add a file
to this list by using `lunatikz add path/to/file`.


#### margin (default: 0pt)


This is the margin that is passed to the

```latex
\documentclass[tikz, margin = 0pt]{standalone}
```


#### style (default: default)


`style` determines the style of the current build. Setting `style` will
overrides `style.file` and `style.macro`.


#### style.file (default: nil)


Lets say, user wants to build the pic with a different colorscheme. Each
different scheme can be seen as a different `style`. Usually, the user will
set some macro to a different colorscheme in some file. Therefore user can
set this `style.file` to that file, and lunatikz will check for that macro
(see `style.macro` for setting which macro to check) in that file. And uses
that style.


#### style.macro (default: nil)


If `style.macro` is set lunatikz will look for first instance of this macro
and reads its first argument as the `style`.

Note: Both `style.file` and `style.macro` should be setted in order for
this to work.


#### style.fromroot (default: false)


(NOTE: not implemented yet, currently the `style.file` is always from the
root directory)

If the `style.file` is relative, ie does not start with a `/`, by default
lunatikz will assume that file to be relative to the current directory from
which lunatikz was invoked. If `style.fromroot` is true, then that path
will be assumed to be relative to the root directory of the project.


#### touch.file (default: need_to_build)


If any of the files are changed or any of the pics that are needed by the
project file needed to be build lunatikz will touch this `touch.file`.
Note: This file will be in the directory of the build pic.


#### touch (default: nil)


Even though `touch.file` is set, lunatikz won't touch the file, `touch` is
needed to be set to true.


#### watch.list (default: nil)


(NOTE: not implemented yet)

TODO: Needs revision

`watch-list` will be a list of files, if modified lunatikz will compile all
of the pics needed for the entire project.


## build subcommand


`build [file]` subcommand will build pics for the specified file. `file` is
optional. If no files are given, lunatikz will look for `build-entry` for the
current directory in the local config, if lunatikz finds it, and the file
exists, lunatikz will build pics for that. If the current directory is inside
a `pics.directory` then `file` is mandatory.

If the file is in `pics.directory`, then lunatikz will check for
`\\begin{tikzpics}` and `\\end{tikzpics}` block, in that file. If it finds
it, lunatikz will build that pic. Otherwise lunatikz will politely refuse.
`--force` will overrides this behaviour, therefore lunatikz will blindly
builds the pic. If it fails, lunatikz will call `pdflatex` _miserable_ and
exits.

(NOTE: `--force` is not yet implemented)


## add subcommand


`add` will add entries to different lists. All of these list are stored
under `.lunatikz/` directory.

List of lists:

- dep_list
- build_entry


#### dep_list


`dep-list` will be the list of dependency files. Basically they are the
files in the `pics.directory`. User can add files to this list and disable
`pics.checking`. This will skip checking for dependencies in the
`pics.directory`. This will improve the performance. But the user needs to
add the dependency files to this list, as they add files to the
`pics.directory`.

Usage will be `lunatikz add --dep-list [files]`

`files` can be the list of files. And it is mandatory to specify the
`files`. It can be relative or absolute paths. But internally lunatikz will
store them as the relative paths from the root directory of the project.


#### build_entry


`build_entry` will be the list of files that are used when `lunatikz build`
is invoked without any files as arguments. lunatikz will check for the
current directory in this list, and if it finds an entry lunatikz will
build that file. Only one file can be specified for one directory.

Usage will be `lunatikz add --build-entry [files]`

`files` can be the list of files. And it is mandatory to specify the
`files`. It can be relative or absolute paths. But internally lunatikz will
store them as the relative paths from the root directory of the project.


## remove subcommand


`remove` will remove entries to different lists. `remove` removes what `add`
adds

# Rest of the README

#wip
