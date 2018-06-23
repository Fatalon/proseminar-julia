# This is also a skeleton Makefile for your LaTex project.
# Feel free to adopt it to your needs.
#
# This Makefile writes the intermediate files to the folder ./tmp.
#
# martin.schroschk (at) tu-dresden.de
# 2.1.2018

PROJECT=proseminar
TEX=pdflatex
BIBTEX=bibtex ./tmp/$(PROJECT)
BUILDTEX=$(TEX) --output-directory=./tmp $(PROJECT).tex

all: tmp
	$(BUILDTEX)
	$(BIBTEX)
	$(BUILDTEX)
	$(BUILDTEX)
	mv tmp/$(PROJECT).pdf . 2> /dev/null

tmp:
	if [ ! -d "./tmp" ]; then mkdir tmp/; fi

reallyclean: clean
	rm -f *.pdf

clean:
	rm -f *.log *.bak *.aux *.bbl *.blg *.idx *.toc *.out *~ *.backup *.vrb *.snm *.nav

