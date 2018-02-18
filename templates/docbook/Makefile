MAX_TEX_RECURSION=4

XML_DECL=/usr/share/xml/declaration/xml.dcl

HTML_SS=/usr/lib/sgml/stylesheet/dsssl/docbook/nwalsh/html/docbook.dsl
#/usr/share/doc/docbook-dsssl/examples/html-siteconfig.dsl

#/usr/share/sgml/docbook/stylesheet/dsssl/ldp/ldp.dsl

PRINT_SS=/usr/lib/sgml/stylesheet/dsssl/docbook/nwalsh/print/docbook.dsl
#/usr/share/doc/docbook-dsssl/examples/print-siteconfig.dsl


all: SYSTEM

SYSTEM: SYSTEM.ps SYSTEM.txt SYSTEM.html

SYSTEM.tex: SYSTEM.xml
	jade -t tex -V tex-backend \
		-d $(PRINT_SS) \
		$(XML_DECL) $<

SYSTEM.dvi: SYSTEM.tex
	-cp -pf prior.aux pprior.aux
	-cp -pf $(shell basename $< .tex).aux prior.aux
	jadetex $<
	if ! cmp $(shell basename $< .tex).aux prior.aux &&	     \
	   ! cmp $(shell basename $< .tex).aux pprior.aux &&	    \
	   expr $(MAKELEVEL) '<' $(MAX_TEX_RECURSION); then	     \
		rm -f $@						;\
		$(MAKE) $@					      ;\
	fi
	rm -f prior.aux pprior.aux

SYSTEM.ps: SYSTEM.dvi
	dvips -f $< > $@

SYSTEM.html: SYSTEM.xml
	jade -t sgml \
		-d $(HTML_SS) \
		$(XML_DECL) $<

SYSTEM.txt: SYSTEM.xml
	jade -t sgml -V nochunks \
		-d $(HTML_SS) \
	$(XML_DECL) $< > dump.html
	lynx -force_html -dump dump.html > $@
	-rm -f dump.html

validate:
	nsgmls -s -wxml $(XML_DECL) SYSTEM.xml

clean:
	rm -f *.html *.aux *.log *.dvi *.ps *.tex *.txt

SYSTEM.htm:
	jade -t sgml \
		-d /usr/share/sgml/docbook/stylesheet/dsssl/modular/html/docbook.dsl \
	$(XML_DECL) SYSTEM.xml $<		

ldpps:
	/usr/bin/dvips -o SYSTEM.ps SYSTEM.dvi
