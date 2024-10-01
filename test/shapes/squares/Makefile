PICS_TOUCH = tikzpics/need_to_build

build: build_pics chapter.pdf

chapter.pdf: chapter.tex $(PICS_TOUCH)
	pdflatex -halt-on-error chapter.tex
	touch chapter.pdf

build_pics:
	../../../lunatikz build chapter.tex

.PHONY: build build_pics
