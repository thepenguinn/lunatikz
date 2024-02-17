PICS_TOUCH = squares/tikzpics/need_to_build allthree/tikzpics/need_to_build circles/tikzpics/need_to_build triangles/tikzpics/need_to_build

build: build_pics main.pdf

main.pdf: main.tex $(PICS_TOUCH)
	pdflatex -halt-on-error main.tex
	touch main.pdf

build_pics:
	lunatikz build main.tex

.PHONY: build build_pics
