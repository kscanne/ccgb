
prefix=/usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libexecdir = $(exec_prefix)/libexec
datadir = $(prefix)/share
pkgdatadir = $(datadir)/corpas

PARADIR = ${HOME}/gaeilge/diolaim/comp
THISDIR = ${HOME}/gaeilge/corpas/corpas
INSTALL = /bin/install -c
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_PROGRAM = /bin/install -c
webhome = /home/kps/public_html/corpas

all : mor.db veicteoir.db ppfaigh

installbin : ppfaigh
	$(INSTALL_PROGRAM) qq $(bindir)/qq
	$(INSTALL_PROGRAM) mutate $(bindir)/mutate
	$(INSTALL_PROGRAM) ppfaigh $(libexecdir)/ppfaigh
	$(INSTALL_PROGRAM) mivec $(libexecdir)/mivec
	$(INSTALL_PROGRAM) commontok $(libexecdir)/commontok
	$(INSTALL_PROGRAM) quotekeep.pl $(libexecdir)/quotekeep.pl

install : all
	$(INSTALL_DATA) mor.db $(pkgdatadir)/mor.db
	$(INSTALL_DATA) veicteoir.db $(pkgdatadir)/veicteoir.db
	$(INSTALL_DATA) stoplist $(pkgdatadir)/stoplist
	$(MAKE) installbin

uninstall :
	rm -f $(pkgdatadir)/mor.db
	rm -f $(pkgdatadir)/veicteoir.db
	rm -f $(pkgdatadir)/stoplist
	rm -f $(bindir)/qq
	rm -f $(bindir)/mutate
	rm -f $(libexecdir)/ppfaigh
	rm -f $(libexecdir)/mivec
	rm -f $(libexecdir)/commontok
	rm -f $(libexecdir)/quotekeep.pl

mor.db : pptog huge.txt
	rm -f mor.db
	cat huge.txt | ./pptog mor.db

clean :
	rm -f *.o ppfaigh pptog *.c~ fadhbanna.txt

distclean :
	$(MAKE) clean
	rm -f veicteoir.db mor.db huge.txt veicteoir.txt

huge.txt :
	(cd $(PARADIR); egrep -H . * | sed 's/: / /' > $(THISDIR)/huge.txt)

fadhbanna.txt : huge.txt
	cat huge.txt | sed 's/ .*//' | sed 's/-b:/:/' | sort | uniq -c | egrep -v '^ *2 ' > fadhbanna.txt

veicteoir.txt : huge.txt
	cat huge.txt | perl builder > veicteoir.txt

veicteoir.db : pptog veicteoir.txt
	rm -f veicteoir.db
	cat veicteoir.txt | ./pptog veicteoir.db

op.o : op.c
	gcc -c op.c

pptog : op.o
	gcc -o pptog op.o -ldb

get.o : get.c
	gcc -c get.c

ppfaigh : get.o
	gcc -o ppfaigh get.o -ldb

installweb :
	$(INSTALL_DATA) index.html $(webhome)
	$(INSTALL_DATA) ll.html $(webhome)
	$(INSTALL_PROGRAM) cc.cgi /home/httpd/cgi-bin
	$(INSTALL_PROGRAM) ccweb /usr/local/bin

.PRECIOUS : mor.db veicteoir.db huge.txt
