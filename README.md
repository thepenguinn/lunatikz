# LunaTikZ - A TikZ picture builder

LunaTikZ is a tikzpicture builder written in LUA. LunaTikZ can resolve
dependancies between different tikzpictures. And only build the modified pics
for a given file.

![](./demo/demo.gif)

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

## Subtikzpicture

`subtikzpicture` is a small package that is inspired from the `circuitikz`
package's `subcircuits` feature. So basically `circuitikz` has a neat feature
called `subcircuits` (Beware: its an experimental one). In `circuitikz`'s
terms, `subcircuits` are chunks of tikz code that can have custom anchors and
can be used in other `circuits`. But it has some disadvantages. It needs to be
written in a way that it is valid inside a `\draw ;` block (because it is
implemented in a way that it is finally drawn with a single `\draw ;` command,
but it's possible to reimplement this in a way that, it allows multiple `\draw ;`
blocks to be included inside the `subcircuit` definitions).

`subtikzpicture` attempts to address the above issue, by reimplementing two similar
macros, namely `subtikzpicturedef` and `subtikzpictureactivate`. Both are analogous
to `circuitikz`'s `ctikzsubcircuitdef` and `ctikzsubcircuitactivate`. But these
new macros allows to define `subtikzpictures` just like one would define a typical
`tikzpicture` block. In other words, we can use normal `\draw ;` and other tikz
commands inside these `subtikzpictures`.

`subtikzpicture` also ensures that the `\subfix` files can be found by each
of the `pics` even when they are nested. `subtikzpicture` with the help of LunaTikZ
will dynamically attach and detach a modified `\subfix` for each of the `pics` as
they are been called (more on this later).

Note: `subtikzpicture.sty` can be found in the root directory of this repo. You
can place it in your project's root directory and use it with `usepackage`,

```latex
\usepackage{subtikzpicture}
```

Or you could just place it where `latex` looks for all the packages.

### Defining a Subtikzpicture

In order to define a `subtikzpicture` and use it properly, they should follow
some guidelines:

- There will be a `dynamic coordinate` named `#1-start` be defined when
the `subtikzpicture` is used. And in the definition, all other `nodes` and
`coordinates` should be anchored relative to this `coordinate`.

- Every `node`, `coordinate`, and all other tikz commands that takes a `name`
should be prefixed with `#1-`, this `#1` will be replaced with the name that
given at the instantiation of the `subtikzpicture`.

- `\subfix` files will be relative to the parent directory of the `pics_directory`,
not relative to the `pics` file.

```latex
%                   +-------------+---------- subcircuit command name
%                   v             v
\subtikzpicturedef{subfigonecircle} {
    center, anothercoord%% <----------------- comma seperated anchors
} {
    \draw (#1-start)% <---------------------- anchoring to (#1-start)
    coordinate (#1-center)% <------------+
    circle [radius = 1]%                 |
    ++(1,0)%                             |
    %% NO EMPTY LINES ALLOWED%           |
    coordinate (#1-anothercoord)% <------+--- subcircuit definition
    ;
}

```

### Activating a Subtikzpicture

After the above definition, `subtikzpicture` needs to calculate the positions
of the custom anchors, and create and store the modified `subfix` macro. For that, we
need to activate the `subtikzpicture`. The following will activate the
`subtikzpicture`.

```latex
\subtikzpictureactivate{subfigonecircle}
```

### Instantiating a Subtikzpicture

Instantiating a defined `subtikzpicture` is also differ a little from
`subcircuit`. `subtikzpicture` instantiation requires three arguments,
one is the `name` of the instance, the next is a `local anchor` and
finally the last one is the `subtikzpicture anchor`.

```latex
\begin{tikzpicture}

    \draw (1,0) (anchor) ;
%                     +-------+-------------------------- name of subcircuit
%                     |       |
%                     |       |   +----+----------------- local anchor
%                     |       |   |    |
%                     |       |   |    |   +----------+-- subtikzpicture anchor to use
%                     v       v   v    v   v          v
    \subfigonecircle {fstcircle} {anchor} {anothercoord}

%                                 +--------------+------- using fstcircle's center as
%                                 |              |        the local anchor to seccircle
%                                 v              v
    \subfigonecircle {seccircle} {fstcircle-center} {anothercoord}%
%   ^                                                            ^
%   |                        drawing another circle named        |
%   +----------------------- seccircle with its anothercoord ----+
%                            at the center of fstcircle

\end{tikzpicture}
```

### Subfix Files

`\subfix` is macro defined by the `subfiles` package. Essentially it helps to
fix the `paths` used in each of the `subfiles`. Let me explain with an example,
let's say we have a project directory structured like so:

```
.
├── chapter_01
│   ├── chapter.tex
│   └── data
│       └── someData.csv
└── main.tex
```

And let's say the `chapter.tex` has this code snippet that plots some data:

```latex
\begin{tikzpicture} []

    \begin{axis} [
            ycomb,
            width = 4in,
            height = 1.5in,
        ]
        \addplot [
            mark = *,
        ] table [
            y = y,
            x = t,
        ] {\subfix{data/someData.csv}};

    \end{axis}

\end{tikzpicture}
```

We can see that the `data/someData.csv` is wrapped in `\subfix`, this will
ensures that the `\addplot` will find `data/someData.csv` no matter where
it's been build from. In this case, if we build the `main.tex` file `\subfix`
will prepend a `chapter_01/` to path.

Like above, while defining `tikzpics`, the file paths should be wrapped in
`\subfix`, LunaTikZ and `subtikzpicture` will ensure these wrapped files are
available while building the pics.

Note: The `tikzpictures` as stored in a particular directory known as a
`pics_directory` (more on this later), but the path to the `\subfix` should be
the relative path from the parent directory of this `pics_directory`.

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
sha256sum
</pre> </td>
<td>
Calculates the hash of <code>\subfix</code> files
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
<td> <code>subfix_cache</code> </td>
<td>
Cache file that lunatikz uses to store the subfix file's info
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

Note: If you are wishing to version control these files, you can
simply ignore `dep_cache` and `subfix_cache`, they are not essential,
lunatikz will rebuild them, if not found. Rest of these files are
essential for properly building the pics.

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

    \draw (1,0) (anchor) ;

    \subfigonecircle {fstcircle} {anchor} {anothercoord}

    \subfigonecircle {seccircle} {fstcircle-center} {anothercoord}

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
\subtikzpicturedef{subfigonecircle} {
    center, anothercoord%
} {
    \draw (#1-start)
    coordinate (#1-center)
    circle [radius = 1]
    ++(1,0)
    %% NO EMPTY LINES ALLOWED
    coordinate (#1-anothercoord)
    ;
}

\subtikzpictureactivate{subfigonecircle}

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

# Installing lunatikz

If you haven't cloned the repo, clone this repo and `cd` into it

```sh
git clone https://github.com/thepenguinn/lunatikz
cd lunatikz
```
lunatikz is a single file in the root directory of this repo. Therefore
you can `cp` it to one of you PATHs.

As long as you have installed all of the prerequsites, lunatikz will work
just fine.

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
ie, current directory or `dirs` has a `.lunatikz/` directory lunatikz will refuse
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

### Flags

#### `--clear`

`--clear` will clears the given keys.

```sh
lunatikz --clear pics.directory style
```

Above will clear the user set `pics.directory` and `style`. After this they
will have their default values.

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

Note: there's currently a `use.subtikz` key which defaults to `true`.
It will be removed in the future. You can simply ignore its existence,
unless you've been using LunaTikZ from when it used `circuitikz`'s
`subcircuits` and your pics are still using `circuitikz`'s `subcircuits`.
If so, you can set `use.subtikz` to `false` by running.

```sh
lunatikz config --clear use.subtikz
```

But you should switch to `subtikzpicture` as soon as possible, because
this will be removed in the coming releases.

## build subcommand

`build` subcommand will build pics for the specified files.

Usage will be:

```sh
lunatikz build [files]
```

`files` is optional. If no files are given, lunatikz will look for
`build_entry` for the current directory, if lunatikz finds it, and the file
exists, lunatikz will build pics for that. If the current directory is inside a
`pics.directory` then `files` is mandatory.

If the file is in `pics.directory`, that is if the given file is an `end pic`,
then lunatikz will check for `\begin{tikzpics}` and `\end{tikzpics}` block (to
make sure that its an `end pic`), in that file. If it finds it, lunatikz will
build that pic. Otherwise lunatikz will politely refuse.

File name of the discrete `end pic` pdf will be `<basename>-<style>.pdf`

### Flags

#### `--output-dir`

`--output-dir` will take relative or an absolute file path. Only used
when you are building discrete `end pics`. If the directory doesn't exist,
lunatikz will create it. And places all the build discrete pics inside it.
If not specified, the outputs will be place in the current directory.

#### `--margin`

`--margin` wiil set the margin of each of the `end pics`. Only applied when
building discrete `end pics`. This does not affect the `margin` config key.
This will be relative to the `margin` config key. ie, if `margin` is `1cm`.
And if you run:

```sh
lunatikz build --margin 2cm tikzpics/onecircle.tex
```

This will generate a pdf file `onecircle-default.pdf` in the current directory,
that has a margin of `1cm + 2cm = 3cm`.

If you want 0cm margin, you can run:

```sh
lunatikz build --margin "-1cm" tikzpics/onecircle.tex
```

This will remove the margin applied by the `margin` config.

The order of `--margin` is also important.

```sh
lunatikz build --margin "-1cm" tikzpics/onecircle.tex --margin "0cm" tikzpics/twocircles.tex
```

First one will have `1cm - 1cm = 0cm` margin. And the second one will have `1cm
+ 0cm = 1cm` margin.

#### `--dry-run`

`--dry-run` will output the standalone files and exits.


## add subcommand

`add` will add entries to different lists. All of these list are stored
under `.lunatikz/` directory.

By default,

```sh
lunatikz add [files]
```

Above will add to the `dep_list` list.

```sh
lunatikz add --build-entry file1 --dep-list file2
```

But this one will add `file1` to the `build_entry` and `file2` to the
`dep_list`.

### Flags

#### `--build-list`

`--build-list` will add to `build_entry` list.

#### `--dep-list`

`--dep-list` will add to `dep_list` list.

List of lists:

- dep_list
- build_entry


### dep_list

`dep-list` will be the list of dependency files. Basically they are the
files in the `pics.directory`. User can add files to this list and disable
`pics.checking`. This will skip checking for dependencies in the
`pics.directory`. This will improve the performance. But the user needs to
add the dependency files to this list, as they add files to the
`pics.directory`.

Usage will be:

```sh
lunatikz add --dep-list [files]
```

`files` can be the list of files. And it is mandatory to specify the
`files`. It can be relative or absolute paths. But internally lunatikz will
store them as the relative paths from the root directory of the project.


### build_entry


`build_entry` will be the list of files that are used when `lunatikz build`
is invoked without any files as arguments. lunatikz will check for the
current directory in this list, and if it finds an entry lunatikz will
build that file. Only one file can be specified for one directory.

Usage will be:

```sh
lunatikz add --build-entry [files]
```

`files` can be the list of files. And it is mandatory to specify the
`files`. It can be relative or absolute paths. But internally lunatikz will
store them as the relative paths from the root directory of the project.


## remove subcommand


`remove` will remove entries to different lists. `remove` removes what `add`
adds

Usage will be same as `add` subcommand.

# Rest of the README

#wip
