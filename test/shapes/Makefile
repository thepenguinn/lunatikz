PICS_TOUCH = squares/tikzpics/need_to_build allthree/tikzpics/need_to_build circles/tikzpics/need_to_build triangles/tikzpics/need_to_build notashape/tikzpics/need_to_build

TEX_FILE = main.tex squares/chapter.tex allthree/chapter.tex circles/chapter.tex triangles/chapter.tex notashape/chapter.tex colorscheme.sty

build: build_pics main.pdf

main.pdf: $(TEX_FILE) $(PICS_TOUCH)
	pdflatex -halt-on-error main.tex
	touch main.pdf

build_pics:
	../../lunatikz build main.tex

.PHONY: build build_pics
