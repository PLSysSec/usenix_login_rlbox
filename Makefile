LATEXMK = latexmk -pdf -shell-escape

.PHONY : FORCE
main.pdf : FORCE
	#$(MAKE) -C ./gnuplot
	$(LATEXMK) main.tex

.PHONY: clean
clean :
	$(LATEXMK) -C
	rm *.aux *.bbl *.dvi

