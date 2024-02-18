# LunaTikZ - A TikZ picture builder

LunaTikZ is a tikzpicture builder written in LUA. LunaTikZ can resolve
dependancies between different tikzpictures. And only build the modified pics
for a given file.

LunaTikZ will read the given `.tex` file and its included files, and takes
every argument to `\includegraphics` macro and tries to build that pdf file
from the corresponding tex file located in the `tikzpics` directories. In order
to use `lunatikz`, the project needs to be structured specifically. And the
project should use `subfiles` and `circuitikz` packages.

# Dependent LaTeX Packages

## Subfiles

`subfiles` will take care of including main file's preamble portion to the sub
files while building tikzpicture and helps to determine which one is the main
file.

## Circuitikz

Currently `circuitikz` has a neat feature called `subcircuits` (Beware: its an
experimental one). In `circuitikz`'s terms, `subcircuits` are chunks of tikz
code that can have custom anchors and can be used in other `circuits`. But it
has some disadvantages. It needs to be written in a way that it is valid inside
a `\draw ;` block (because it is implemented in a way that it is finally drawn
with a single `\draw ;` command, but it's possible to reimplement this in a way
that allows multiple `\draw ;` blocks to be included inside the `subcircuit`
definitions, more on that later).

The above mentioned disadvantage also means that we can't use anything that are
parsed by LaTeX or any other packages other than TikZ itself. This means no
`if elses` and `newcommands` with optional arguments (it's possible to use
`newcommands` with no optional arguments though). (Atleast I couldn't figure
out a way to do the above mentioned things with `subcircuits`)

### Defining a Subcircuit

```latex
%                   +-------------+---------- subcircuit command name
%                   v             v
\ctikzsubcircuitdef{subfigonecircle} {
    center, anothercoord%% <----------------- comma seperated anchors
} {
    coordinate (#1-center)% <------------+
    circle [radius = 1]%                 |
    ++(1,0)%                             |
    %% NO EMPTY LINES ALLOWED%           |
    coordinate (#1-anothercoord)% <------+--- subcircuit definition
}

```

### Activating a Subcircuit

After the above definition, `circuitikz` needs to calculate the positions of
the custom anchors. For that, we need to activate the `subcircuit`. The
following will activate the `subcircuit`

```latex
\ctikzsubcircuitactivate{subfigonecircle}
```

### Using a Subcircuit

```latex
\begin{tikzpicture}

    \draw%            +-------+------------------- name of subcircuit
%                     |       |
%                     |       |   +----------+---- anchor to use
    (1,0)%            v       v   v          v
    \subfigonecircle {fstcircle} {anothercoord}

    (fstcircle-center)% <------------------------- using fstcircle's center
    \subfigonecircle {seccircle} {anothercoord}%   as next coordinate
%   ^                                         ^
%   +-----------------------------------------+--- drawing another circle named
%                                                  seccircle with its anothercoord
    ;%                                             at the center of fstcircle

\end{tikzpicture}
```


# Getting Started

To get started using LunaTikZ, you need to become familiar with the **LunaTikZ
Workflow**. By using LunaTikZ you are basically seperating all of the TikZ pics
from your document. In that way your document and your figures are completetly
seperate from each other. The only link to the pics will be an `\includegraphics`
macro. And LunaTikZ will be responsible for building that pic from this link.


```
+---------------+              +---------------+
|               |              |               |
|               |              |               |
|               |              |               |
|               |   LunaTikZ   |               |
| Your Document | <==========> | Your TikZpics |
|               |              |               |
|               |              |               |
|               |              |               |
|               |              |               |
+---------------+              +---------------+
```

All the pics are stored in the `pics directory`. And LunaTikZ will read all
these `\includegraphics` and resolves all the needed pics and decides whether
they are needed to be build. And if needed, LunaTikZ will build them into pdf
files for `\includegraphics`.

Below depicts a rough flow chart of this whole process.


```
+----------------------+     +----------------+     +----------------------+
|    Looks for all     |     | Finds TikZ Pic |     |     Resolves its     |
| the \includegraphics | --> | file for each  | --> |      Dependency      | ---+
+----------------------+     +----------------+     +----------------------+    |
                                                                                |
                                                                                |
                                                                                |
+----------------------+     +----------------+     +----------------------+    |
|  Produces the pdfs   |     |  If Modified,  |     | Checks any Dependent |    |
| for \includegraphics | <-- | Build that Pic | <-- |  File has Modified   | <--+
+----------------------+     +----------------+     +----------------------+

```

## Prerequsites

Beside, above mentioned LaTeX packages, LunaTikZ rely on some other command line
tools. Table of dependencies:

<table>

<tr>
<td>
Package
</td>
<td>
Description
</td>
</tr>

<tr>
<td> <pre>
lua5.3
</pre> </td>
<td>
Ofcourse, LunaTikZ is written in lua.
</td>
</tr>

<tr>
<td> <pre>
latex
</pre> </td>
<td>
LunaTikZ needs a local install of LaTeX
</td>
</tr>

<tr>
<td> <pre>
pdflatex
</pre> </td>
<td>
<code>pdflatex</code> compiles the pdfs
</td>
</tr>

<tr>
<td> <pre>
pdftk
</pre> </td>
<td>
Helps to split pdf into seperate pdf files
</td>
</tr>

<tr>
<td> <pre>
core-utils
</pre> </td>
<td>
<code>mv</code>, <code>cp</code>, <code>readlink</code>,
<code>mkdir</code>, <code>rm</code>, <code>find</code>,
<code>stat</code>, <code>pwd</code>, <code>test</code>,
<code>touch</code>. You need all of these. If you have a typical
Linux install, you would probaly have all of these installed.
</td>
</tr>

</table>

## LunaTikZ Directory

At the root of every lunatikz project directory, there will be a `.lunatikz/`
directory. This is where lunatikz will store project related information,
config, and caches. Here is a table of files that lunatikz stores in the
`.lunatikz/` directory:

<table>

<tr>
<td> Files </td> <td> Description </td>
</tr>

<tr>
<td> <code>config</code> </td>
<td>
Stores the local config of the lunatikz directory
</td>
</tr>

<tr>
<td> <code>dep_cache</code> </td>
<td>
Cache file that lunatikz uses to store the dependancy tree of pics
</td>
</tr>

<tr>
<td> <code>build_entry</code> </td>
<td>
Stores the build entries for each of the directories
</td>
</tr>

<tr>
<td> <code>dep_list</code> </td>
<td>
List of local dependencies, ie, the name and the relative path from project's
root directory
</td>
</tr>

</table>

## Pics Directory

Pics Directory is where all the `tikzpictures` are stored. Any directory inside
a LunaTikZ project directory can have such a pics directory. For an example:

```
.
├── circles
│   ├── chapter.tex
│   └── tikzpics
│       ├── need_to_build
│       ├── onecircle.tex
│       ├── subfigonecircle.tex
│       ├── subfigtwocircles.tex
│       └── twocircles.tex
├── main.tex
└── tikzpics
```

Here in the above example, `tikzpics/` is the pics directory.


## Types of Pics

There are two kinds to pics. One kind is a `sub pic` and the other is an `end
pic`. The difference between these two types of pics is that, one cannot be a
dependency of other `pics` and the other can't be build into a `pdf` file.

`end pics` cannot be other pic's dependency (that is why they are called `end`
pics). On the other hand, `sub pics` can't be converted to pdfs directly. If
you want to convert a `sub pic` into a pdf, you need to wrap that `sub pic`
with an `end pic`. Then link that `end pic` from the main document using
`\includegraphics`.

### End Pics

End pics has the typical tikzpicture `begin` `end` block. That is, this one.

```latex
\begin{tikzpicture}

    \draw

    (1,0)
    \subfigonecircle {fstcircle} {anothercoord}

    (fstcircle-center)
    \subfigonecircle {seccircle} {anothercoord}

    ;

\end{tikzpicture}
```

Each `end pic` can and must have only one of these blocks. And it should be an
`tikzpicture` environment. Even if you are using `circuitikz`, you can use
`tikzpicture` environment instead of `circuitikz` environment. It should work
just like before.

NOTE: The file name of an `end pic` must be the same as in the
`\includegraphics` with `.pdf` replaced with `.tex`. ie, if the name of the
`end pic` file is `onecircle.tex` and it is located in `tikzpics/` directory,
then `\includegraphics` would be:

```latex
\includegraphics [any optional arguments] {tikzpics/onecircle.pdf}
```

It could be a relative path or an absolute (don't do this, I know you are
better than that) one. Just pretend that there is a `.pdf` file beside the `end
pic` that you want to include, with the same basename and `.pdf` extention. And
LunaTikZ will do the rest of the **Magic**.

### Sub Pics

Sub pics are the pics that can be other pic's dependencies. They don't have the
typical `begin` `end` blocks. Instead they will have a subcircuit `definition`
and `activation` blocks. And they can also contain any other `newcommand`
definitions that will act on the above subfigure after it's been drawn. Maybe,
like a newcommand to label the above subfigure. So that you only need to draw
the labels, when you need them.(If you are using this subfigure in some other
subfigure, then you will be implementing another newcommand to draw its
labelling in its pics file.)

Typical content of a Sub Pic will be:

```latex
\ctikzsubcircuitdef{subfigonecircle} {
    center, anothercoord%
} {
    coordinate (#1-center)
    circle [radius = 1]
    ++(1,0)
    %% NO EMPTY LINES ALLOWED
    coordinate (#1-anothercoord)
}


\ctikzsubcircuitactivate{subfigonecircle}

%% Any other newcommands you like to implement
%% goes here.
```

NOTE: The file name of a `sub pic` should be the same as the first argument to
`\ctikzsubcircuitdef`, with `.tex` extention. ie, in the above example, the
file name would be `subfigonecircle.tex`. And it should be placed inside the
pics directory.

## Typical LunaTikZ Workflow

If you want to see a a working, configured LunaTikZ project, you can take look
at the example project in the `test/shapes/` directory of this repo.

First of all, clone this repo.

```sh
git clone https://github.com/thepenguinn/lunatikz
cd lunatikz/test/shapes
```

Then look inside all of the `tikzpics/` directories, you won't be seeing any
pdf files. In order to generate them, you need to build them with lunatikz. Run
this command from `test/shapes/` directory.

```sh
../../lunatikz build main.tex
```

If everything is right, (ie, you have installed all the prerequsites) lunatikz
will build the pdfs from those `.tex` files. Now look inside all of the
`tikzpics/` directories, you could see the `.pdf` files, lunatikz generated.

Now you can compile the `main.tex` file using `pdflatex`.

```sh
pdflatex -halt-on-error main.tex
```

This will generate the final document.

# Command Line Interface

`lunatikz`'s command line interface is similar to that of `git`. lunatikz has
different subcommands. Here is a table of all of the currently implemented
subcommands:


<table>

<tr>
<td> Subcommands </td> <td> Description </td>
</tr>

<tr>
<td> <code>init</code> </td>
<td>
To initialize a lunatikz directory.
</td>
</tr>

<tr>
<td> <code>config</code> </td>
<td>
To set and clear config.
</td>
</tr>

<tr>
<td> <code>build</code> </td>
<td>
To build tikzpictures.
</td>
</tr>

<tr>
<td> <code>add</code> </td>
<td>
To add files to various lists.
</td>
</tr>

<tr>
<td> <code>remove</code> </td>
<td>
To remove files from various lists.
</td>
</tr>

</table>

## init subcommand


`init` initializes a lunatikz directory.

Usage will be:

```sh
lunatikz init [dirs]
```

This will initialize a lunatikz directory in the `dirs`. `dirs` is optional and
can be more than one. if nothing is given, lunatikz will initialize the current
directory as a lunatikz directory. If ran inside another lunatikz directory,
ie, current directory or `dirs` has a `.lunatikz` directory lunatikz will refuse
to initialize the directory as a lunatikz directory (because it's already one).
Otherwise, lunatikz will initialize the dir as a lunatikz directory.

If a non existant `dirs` was given, lunatikz will create that directory and
initializes it as a lunatikz directory.


## config subcommand

lunatikz `config` will help the user to set configuration on a per project
basis, or a global wide basis (NOTE: global config is not yet implemented).
The global `config` will be read everytime the user invokes lunatikz then
lunatikz will read per project `config` and merges it with global `config`.
The per project `config` can override the global `config`. (NOTE: since
global config is not implemented yet, no merging will happens)

Usage will be:

```sh
lunatikz config pics.directory mypics style catppuccin touch
```

The above snippet will set `pics.directory` to `mypics`, `style` to
`catppuccin` and enables `touch`.

Running `lunatikz config` will print the current config for the current project
directory.

### flags

#### `--clear`

`--clear` will clears the given keys.

```sh
lunatikz --clear pics.directory style
```

#### `--global`

NOTE: Not implemented yet.

#### `--local`

NOTE: Not implemented yet.

### configurable parameters

#### pics.directory

`pics.directory` is where the pics are stored. This should not contain any
newlines or forward slashes. If preset lunatikz will silently turnicates them.

#### pics.skip

If true, skips reading all the files exists in `pics.directory` instead reads
the dependency list from `.lunatikz/dep_list`, and the user can add files to
this list by using `lunatikz add path/to/file` (see `add` subcommand).

#### margin

This is the margin that is passed to the `\documentclass` of `standalone.main`
file. This will be wrapped in curly braces.

```latex
\documentclass[tikz, margin = {0pt}]{standalone}
```

#### style

`style` determines the style of the current build. Setting `style` will
takes precedence than `style.file` and `style.macro`. ie, if `style` is
set, lunatikz won't look for `style` in `style.file`.

#### style.file

Lets say, you want to build the pic with a different colorscheme. Each
different scheme can be seen as a different `style`. Usually, the colorscheme
is set by setting some macro to a different colorscheme in some file. Therefore
we can set this `style.file` to that file, and lunatikz will check for that
macro (see `style.macro` for setting which macro to check) in that file. And
uses that style. Cannot have any newline charaters.

#### style.macro

If `style.macro` is set lunatikz will look for first instance of this macro
and reads its first argument as the `style`.

Note: Both `style.file` and `style.macro` should be setted in order for
this to work.

#### style.fromroot

(NOTE: not implemented yet, currently the `style.file` is always from the
root directory)

If the `style.file` is relative, ie does not start with a `/`, by default
lunatikz will assume that file to be relative to the current directory from
which lunatikz was invoked. If `style.fromroot` is true, then that path
will be assumed to be relative to the root directory of the project.

#### touch.file

If any of the `end pic` needed to be rebuild, then we need to inform the build
system (that we use to build the rest of the document) that it needs to rebuild
the document.

`touch.file` is trying to solve this issue. You can set `touch.file` to some
file and if any of the `end pics` are rebuild, lunatikz will touch this file.
(only works when `touch` is enabled). If you are using `make` you can run
`lunatikz` on the file initially and tell `make` to rebuild the document if
this `touch.file` is changed.

Cannot have any newline or forward slashes in it. If present lunatikz will
silently turnicates them.

#### touch

Even though `touch.file` is set, lunatikz won't touch the file, `touch` is
needed to be set to true.

#### standalone.main

`standalone.main` will be the file name of main standalone file. Should not
contain any newlines or forward slashes. If present, will be silently
turnicated.

#### standalone.sub

`standalone.sub` will be the file name of sub standalone file. Should not
contain any newlines or forward slashes. If present, will be silently
turnicated.

#### standalone.tmpdir

`standalone.tmpdir` will be the name of the tmp directory lunatikz creates for
building pdfs. Should not contain any newlines or forward slashes. If present,
will be silently turnicated.

### Config Keys and Defaults Values

<table>

<tr>
<td> Config Keys </td>
<td> Defaults Values </td>
</tr>

<tr>
<td> <code>pics.directory</code> </td>
<td> <code>tikzpics</code> </td>
</tr>

<tr>
<td> <code>pics.skip</code> </td>
<td> <code>false</code> </td>
</tr>

<tr>
<td> <code>margin</code> </td>
<td> <code>0pt</code> </td>
</tr>

<tr>
<td> <code>style</code> </td>
<td> <code>default</code> </td>
</tr>

<tr>
<td> <code>style.file</code> </td>
<td> <code>nil</code> </td>
</tr>

<tr>
<td> <code>style.macro</code> </td>
<td> <code>nil</code> </td>
</tr>

<tr>
<td> <code>style.fromroot</code> </td>
<td> <code>true</code> </td>
</tr>

<tr>
<td> <code>touch.file</code> </td>
<td> <code>need_to_build</code> </td>
</tr>

<tr>
<td> <code>touch</code> </td>
<td> <code>false</code> </td>
</tr>

<tr>
<td> <code>standalone.main</code> </td>
<td> <code>_standalone_main</code> </td>
</tr>

<tr>
<td> <code>standalone.sub</code> </td>
<td> <code>_standalone_sub</code> </td>
</tr>

<tr>
<td> <code>standalone.tmpdir</code> </td>
<td> <code>_standalone_tmp</code> </td>
</tr>

</table>


## build subcommand

`build` subcommand will build pics for the specified file. `file` is
optional. If no files are given, lunatikz will look for `build-entry` for the
current directory in the local config, if lunatikz finds it, and the file
exists, lunatikz will build pics for that. If the current directory is inside
a `pics.directory` then `file` is mandatory.

If the file is in `pics.directory`, then lunatikz will check for
`\begin{tikzpics}` and `\end{tikzpics}` block, in that file. If it finds
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
