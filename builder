#!/bin/bash
# filter -- input stream is the list of corpus words to be grepped out
# of corpus and line numbers stored in veic.db
# N.B. the "grep -w" will index words like "ábhar" when it appears in
# the corpus as "d'ábhar", or "organisation" when it is really "organisation's"
#  This seems fine for now; otherwise just have to kill the -w and make
#  the search pattern a bit fancier.

LIBEXECPATH=/usr/local/libexec

grep ' ' huge.txt | sed 's/^[^ ]* //' | ${LIBEXECPATH}/commontok |
while read patrun
do
	( echo "${patrun}"; grep -i -w "${patrun}" huge.txt | sed 's/ .*//') |
	sed -n 'H; ${x; s/\n/ /g; p}' | sed 's/^ //'
done
