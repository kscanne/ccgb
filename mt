#!/bin/bash
LIBEXECPATH=/usr/local/libexec
DATAPATH=/usr/local/share/corpas
TEMPFILE=`mktemp`
tr -d '&~' | lemma | tr "[:upper:]" "[:lower:]" | perl -n -e '
chomp;
if (m/^(\S+)\t\S+\t(\S+)$/) {
print "$1\n";
print "$2\n" unless ($1 eq $2);
}
else {
print "\n";
}
' | grep -v '^.$' | grep -v -x -f ${DATAPATH}/stoplist |
while read x
do
	if [ -z "${x}" ]
	then
		cat ${TEMPFILE} | ${LIBEXECPATH}/ppfaigh ${DATAPATH}/veicteoir.db y
		echo
		rm -f ${TEMPFILE}
		touch ${TEMPFILE}
	else
		echo "${x}" >> ${TEMPFILE}
	fi
done | perl ${HOME}/clar/libexec/mt.pl | 
while read y
do
	if [ -z "${y}" ]
	then
		echo '-----------------------------------------------------'
	else
#		echo "${y}" | sed 's/^[^ ]* /\nScore=/'
		HIT=`echo "${y}" | sed 's/ .*//'`
		echo
		echo "#: ${HIT}"
		echo "${HIT}" | ${LIBEXECPATH}/ppfaigh ${DATAPATH}/mor.db n | sed 's/"/\\"/g; s/^/msgid "/; s/$/"/'
		echo "${HIT}" | sed 's/-b:/:/' | ${LIBEXECPATH}/ppfaigh ${DATAPATH}/mor.db n | sed 's/"/\\"/g; s/^/msgstr "/; s/$/"/'
	fi
	
done
rm -f $TEMPFILE
