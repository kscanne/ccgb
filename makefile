
prefix=/usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libexecdir = $(exec_prefix)/libexec
datadir = $(prefix)/share
pkgdatadir = $(datadir)/corpas

PARADIR = ${HOME}/gaeilge/diolaim/comp2
THISDIR = ${HOME}/gaeilge/corpas/corpas
INSTALL = /bin/install -c
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_PROGRAM = /bin/install -c
webhome = /home/kps/public_html/corpas

all : mor.db veicteoir.db ppfaigh

install : all
	$(INSTALL_DATA) mor.db $(pkgdatadir)/mor.db
	$(INSTALL_DATA) veicteoir.db $(pkgdatadir)/veicteoir.db
	$(INSTALL_DATA) stoplist $(pkgdatadir)/stoplist
	$(INSTALL_PROGRAM) qq $(bindir)/qq
	$(INSTALL_PROGRAM) ppfaigh $(libexecdir)/ppfaigh
	$(INSTALL_PROGRAM) mivec $(libexecdir)/mivec

uninstall :
	rm -f $(pkgdatadir)/mor.db
	rm -f $(pkgdatadir)/veicteoir.db
	rm -f $(pkgdatadir)/stoplist
	rm -f $(bindir)/qq
	rm -f $(libexecdir)/ppfaigh
	rm -f $(libexecdir)/mivec

mor.db : pptog huge.txt
	cat huge.txt | pptog mor.db

clean :
	rm -f *.o ppfaigh pptog

distclean :
	$(MAKE) clean
	rm -f veicteoir.db mor.db huge.txt

huge.txt : $(PARADIR)
	(cd $(PARADIR); egrep -H . * | sed 's/: / /' > $(THISDIR)/huge.txt)

veicteoir.db : pptog huge.txt
	bash mivec -t | pptog veicteoir.db

v.txt : huge.txt mivec
	bash mivec -t > v.txt

op.o : op.c
	gcc -c op.c

pptog : op.o
	gcc -o pptog op.o -ldb
	cp -f pptog ${HOME}/clar/denartha

get.o : get.c
	gcc -c get.c

ppfaigh : get.o
	gcc -o ppfaigh get.o -ldb

installweb :
	$(INSTALL_DATA) index.html $(webhome)
	$(INSTALL_PROGRAM) cc.cgi /home/httpd/cgi-bin
	$(INSTALL_PROGRAM) ccweb /usr/local/bin

.PRECIOUS : mor.db veicteoir.db huge.txt
