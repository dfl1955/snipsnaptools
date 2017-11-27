#!/bin/bash

# put in the licence code, this is mine so can be what I want.
# simplify the versions control stuff

# This program browses the file system and deletes and archives
# snipsnap backups, snipsnap web server and error logs. 

# $Id: tidylogs.sh,v 1.2 2007/01/02 17:43:24 snipsnap Exp snipsnap $

# Author: Dave Levy
# Revision 1.3 2008/08/02 
# No RCS, adopted for Ubuntu and simplyfied
# $Log: tidylogs.sh,v $
# Revision 1.2  2007/01/02 17:43:24  snipsnap
# First working version, ready for installation into cron
#
# Revision 1.1  2006/12/24 10:24:19  snipsnap
# Initial revision
#
# $Revision$

pname=$(basename $0)
# $Revison$
pver=1.3
USAGE="${pname} [help]|[version]"

# These are configuration variables and will vary. They should be
# ameded as appropriate

. /home/snipsnap/bin/functions

SNIPSNAP_HOME=$(getconfigval SNIPSNAP_HOME)

# put in the parameter validation code

dprint()
{
	echo $pname $pver $*
}

case $1 in
-?|?|help|--help) echo $USAGE ; exit ;;
-v|-ver|version|--version) dprint ; exit ;;
esac

dprint ... starts @ $(date)

# we can do more than one this way
for directory in $SNIPSNAP_HOME
do
	if [ ! -d $directory ]
	then
		dprint error -  directory $directory is not a directory
		exit 1
	fi
done

dprint "###############################################################"
#
# requestlog

# This is installation specific but the request log is hard coded by
# snipsnap to be in the directory in which snipsnapmgr is called. 
# However I use a find to identify the request logs using the HOME 
# directory as a start point. Bottom line this needs to be tested for
# each new install.

requestloglocation=$SNIPSNAP_HOME
cd $requestloglocation

# Days Old
old_requestlog=7
set plural ; [ ${old_requestlog} -gt "1" ] && plural=s
requestlog_namestring=.request.log

displaylog_name="http request logs"
dprint processing $displaylog_name

# find the files to be deleted
oldlogs=$(find ${requestloglocation}  \
		-maxdepth 1           \
		-name "*${requestlog_namestring}*" \
		-mtime +${old_requestlog} )
#
# This next bit deletes the unwanted requestlogs and displays a report
# Its complexity is due to managing plurals and the empty set
#
set lognames
counter=0
if [ ! -z oldlogs ]
then
	dprint deleting ${displaylog_name} over ${old_requestlog} day${plural} old
	for i in $oldlogs
	do
		lognames="${lognames} $(basename $i)"
		#rm $i
		counter=$(expr $counter + 1)
	done
fi
case ${counter} in
0)	dprint No request logs over ${old_requestlog} day${plural} old ;;
1)	dprint $oldlogs deleted ;;
*)	dprint $lognames ... deleted
	dprint $counter $displaylog_name deleted
	;;
esac

	
dprint "#############################################################"
#
# errorlog

errorloglocation=$SNIPSNAP_HOME/logs
cd $errorloglocation
# This is days, do not set to less than 3
keeplogs=7
unset plural ; [ $keeplogs > 1 ] && plural=s 
requestlog_namestring="8668 error log"
displaylog_name="snipsnap error logs"

dprint processing $displaylog_name
n1="./$(basename ${errorloglocation})"
dprint weeding ${n1}, keeping files over $keeplogs day${plural} old
dprint weeding ${displaylog_name} files

# looks fixed by snipsnap
errorlogpfx="snipsnap-8668-"
# logfiles holds all logfiles, we want all but the $keeplogs most recent
# so lets use a find, this returns all those older than keeplogs days old
logfiles=$(find ${errorloglocation}  \
		-maxdepth 1           \
		-name "*${errorlogpfx}*" \
		-mtime +${keeplogs} )
# 
# there is now a function called xoldfiles in the functions file
# which will return the names of all but the n newest files in a
# directory
#
sum2delete=$(echo $logfiles|wc -w)
case ${sum2delete} in
0)	dprint there are no files over $keeplogs day${plural} old
	;;
1)	dprint deleting $xfiles
	#rm $xfiles
	dprint $xfiles deleted
	;;
*)	dprint deleting $xfiles
	#rm $xfiles 
	dprint $sum2delete files deleted
	;;
esac
dprint "###############################################################"
#
# dumps

xmlloglocation=$(getconfigval BACKUP)
if [ ! -d $xmlloglocation ]
then
	dprint config error  xml log location does not exist
	exit 100
fi
displaylog_name="snipsnap xml dumps"
dprint processing $displaylog_name
dprint backups are held in $xmlloglocation
cd $xmlloglocation
dprint current directory is  `pwd`

# how long should I keep a dump
keeplogs=31
# this next string is used to find the backup name
# it should allow a parameter to override it.
dumppattern=$(getconfigval EXPORT_PFX)
historylocation=$(getconfigval HISTORY)

allfiles=$(ls -t ${dumppattern}* )
mostrecent=$(ls -t ${dumppattern}* | head -1)
oldfiles=$(xoldfiles $(pwd) ${keeplogs})
#
# this originally wrote the occassional copy to an export directory
# other systems would pick it up. Not sure if I want this, but if I 
# do it should be part of the samba exports, or maybe /var/www

# if first of the month copy it to History and gzip it

# possibly the next two lines better done using variable meta characters
# but I need my ksh manual for that
cdatemostrecent=$(stat --format="%z" ${mostrecent} | cut -f1 -d" " )
cdaymostrecent=$(echo $cdatemostrecent | cut -f3 -d"-")

# the test date i.e. 01 should be held in a variable and maybe forceable 
# from the command line. (Although maybe the force should be in the backup 
# script which means that this should be functioned or enscripted and called
# from either.
if [ ${cdaymostrecent} -eq "01" ]
then
	dprint archives are held in ${historylocation}
	dprint $mostrecent is the most recent dump
	dprint it was created on $cdatemostrecent, the 1st of the month
	dprint processing a monthly history archive
	if [ ! -f ${historylocation}/${mostrecent}.gz ]
	then
	    dprint copying $mostrecent to $(basename ${historylocation})
	    cp ${mostrecent} ${historylocation} 
	    dprint gnuzipping ...
	    gzip ${historylocation}/${mostrecent}
	    dprint gzip done
	else
	    dprint historical ${mostrecent}.gz already exists, 
	    dprint no further copy made
	fi
fi

# get rid of stuff over 31 days old
unset plural; set plural ; [ ${keeplogs} -gt "1" ] && set plural=s

dprint processing dumps in $(pwd)

# These three lines have been copied down from elsewhere in the file
# This where they are needed
# allfiles=$(ls -t davelevy.info*)
# mostrecent=$(ls -t davelevy.info* | head -1)
keeplogs=31
unset plural ; set plural ; [ ${keeplogs} -gt "1" ] && plural=s

dprint deleting ${displaylog_name} over ${keeplogs} day${plural} old

# requires that cwd is the XML log directory

dumppattern=$(getconfigval EXPORT_PFX)

oldfiles=$( find . -maxdepth 1 -name "${dumppattern}*"  -mtime +${keeplogs} )
no_oldfiles=$(echo $oldfiles | wc -w)
[ -z $oldfiles] && no_oldfiles=0 

case $no_oldfiles in
0)	dprint there are no files over ${keeplogs} day${plural} old ;;
1)	dprint $oldfiles deleted ;;
*)	dprint $oldfiles ... deleted
	dprint $no_oldfiles $displaylog_name deleted
	;;
esac

dprint ends @ `date`
