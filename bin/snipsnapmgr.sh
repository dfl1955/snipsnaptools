#!/bin/sh

############################################################################
#
# GNU GENERAL PUBLIC LICENSE

# Copyright (C) 2007 Dave Levy

# This program is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the Free 
# Software Foundation; either version 2 of the License, or (at your option)
#  any later version.

# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License 
# for more details.

# For a copy of the GNU General Public License, look in the Snipsnap install
# directory for 'licence.txt' otherwise write to the 

#	Free Software Foundation Inc., 
#	675 Mass Ave, Cambridge, MA 02139, USA.

LICENCE_TEXT=" Copyright (C) 2007 Dave Levy"
WARRANTY_TEXT=" comes with ABSOLUTELY NO WARRANTY;"

############################################################################
#
# Version Control Block

# Ver 1.5 - Changes for Ubuntu 9.0 and new filesystem naming conventions
#           use of an ~/etc/config file, moved functions to functions file

# $Log: snipsnapmgr.sh,v $
# Revision 1.4  2007/01/15 12:45:08  snipsnap
# GPL terms and displays inserted
#
# Revision 1.3  2006/12/24 10:17:49  snipsnap
# Full method orientated structure, supporting start, stop, restart, status,
# start with debug and admin. This supports a single instance of snipsnap.
# There is a $HOME/etc/config file which holds some installation parameters. The
# restart function is not done. Errorlog file nameing has been implemented.
#

# Ver 1.2 - Using inline function to discover running processes
# Ver 1.1 - Original Version - taken fron snipsnap 1.0b3 uttoxeter

# functions dprint, showpids, snipsnapstart, snipsnapstatus

# programs basename, ps, grep, head, cut, java, echo, uname and maybe kill

# I need an admin function and a snipsnapstop which may invoke the admin 
# function. See also snipsnapstart function which isn't finished

VER=1.4
sname=`basename $0`

############################################################################
#
# Parameter Control
#
# There can be additional parameters to follow the -admin flag, this is currentl# wrong, best answer 
# is to not permit the -v functions with admin.

USAGE="`basename $0` [-admin <other admin args> ]|[[ abort] | [-h|h|help|-?] | restart | start [-debug|debug] | status | stop ] [ -v|v|verbose ]"

# the verbose parameter nb the verbose parameter can be in position 2 & 3

case $2 in
-v|v|-verbose|verbose)  \
	VERBOSE=1 ;;
-debug|debug)		 \
	VERBOSE=0
	if [ ${#} -eq "3" ];then
        	case $3 in
        	-v|v|-verbose|verbose)  VERBOSE=1 ;;
        	*)			VERBOSE=0 ;;
        	esac
	fi
	;;
*)	VERBOSE=0 ;;
esac

dprint()
{
#  Not the most efficient tecnique, but we don't run it that often

	if [ $VERBOSE -eq "1" ]; then
		echo $sname $VER $*
	fi
}
# Licence stuff only displayed if runs verbose

dprint $LICENCE_TEXT
dprint $WARRANTY_TEXT
dprint ... starts

############################################################################
#
. $HOME/bin/functions


############################################################################
#
# Environment Control
#
# This still works, I could move it to the start section, but haven't
if [ "$2" = "-debug" ]
then
    DBG="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5000"
	dprint debug flags are set
fi

ETC=${HOME}/etc
if [ ! -d ${ETC} ]; then
	echo ${ETC} does not exist or is not a directory
	exit 200
fi

# The next line could be cat ${ETC}/config | egrep -v '^#" | grep JAVA_HOME | cut -f2 -d"=" but isn't

#JAVA_HOME="/usr/java/j2sdk1.4.2_04"
#JAVA_HOME=$(cat $HOME/etc/config | egrep -v '^#' | grep JAVA_HOME | cut -f2 -d"=")
JAVA_HOME=$( getconfigval JAVA_HOME)
if [ "$JAVA_HOME" != "" ]; then
  	JAVA=$JAVA_HOME/bin/java
else
  	JAVA=java
fi

# The snipsnap guys recommend that the java env is inherited from $cwd

SNIPSNAP_HOME=$(cat $HOME/etc/config | grep SNIPSNAP_HOME | cut -f2 -d"=")
SNIPSNAP_HOME=$( getconfigval SNIPSNAP_HOME )
cd ${SNIPSNAP_HOME}

# This is taken from the original code, it should analyse the environment and 
# set the JAVA_OPTS variable - I have left this unchanged, except that since I
# am running this on a small memory system, I have deleted the line offered for
# high RAM and 

case "`uname`" in
IRIX*)	JAVA_OPTS="$JAVA_OPTS" ;;
*)	JAVA_OPTS="$JAVA_OPTS -server" ;;
esac

JAVA_OPTS="$JAVA_OPTS -DentityExpansionLimit=1000000 -Djava.awt.headless=true -Xmx512m"
# uncomment if you have a lot of memory and want optimizations
JAVA_OPTS="$JAVA_OPTS -Xsqnopause -XX:+UseLWPSynchronization -Xms512m -Xmx1024m -Xss256k -XX:MaxNewSize=96m -XX:MaxPermSize=512m"


############################################################################
#
#  Process Control
#
snipsnapadmin()
{
    echo  executing: $JAVA -jar lib/snipsnap-utils.jar $*
    $JAVA -jar lib/snipsnap-utils.jar $*
}

# I need to force the request logs location, not to mention the classpath
# inheritance it almost certainly needs a cd $HOME/snip*

snipsnapstart()
{
# I think we need either a cd to ../lib, or a -cp flag
# This is a bad server log technique, and I need to understand the request 
# log location
instanceName=davelevy.info # Not Used
instancePort=8668          # This ought to be discoverable
datestring=`date +%Y%m%d`
errorlogname=$(uniquefn snipsnap-${instancePort}-${datestring}-error log)
errorlogname=${HOME}/logs/$(uniquefn snipsnap-${instancePort}-${datestring}-error log)
#errorlogname=snipsnap-${instancePort}-${datestring}-error.log
$JAVA $JAVA_OPTS $DBG -Dlauncher.errlog=${errorlogname} -jar lib/snipsnap.jar $* &
# do I need a sleep
}
snipsnapstatus()
{

toppid=`showpids -top`       # if pid list is full a number > zero, else 0
if [ ! ${toppid} -eq "0" ]; then
	boolstatus=1 
else
	boolstatus=0
fi
echo $boolstatus
}

casestart=y
mode=$1
case $1 in
-admin|admin)	shift
		echo `basename $0` $VER ... admin mode selected - $*
		snipsnapadmin $*
  		exit
		;;
-h|h|help|-help|-?)	
		echo $USAGE
		exit 0 ;;
-restart|restart)	# needs start, status and stop as functions
		;;
-start|start)   # if not running start
		runstate=`snipsnapstatus`
		if [ $runstate ]; then
			snipsnapstart
		else
			case $VERBOSE in
			1)    dprint start requested already running 
			      ;;
			*)    : ;;
			esac
		fi	
		exit 0
		;;
-status|status) if [ ${VERBOSE} -eq "1" ]; then
			dprint ... checking status
			pids=`showpids`
			runstate=`snipsnapstatus`
			#echo runstate is $runstate
#case $runstate in
#0)	echo runstate 0 ;;
#1)	echo runstat 1 ;;
#esac
			if [ ! ${runstate} ]
			then
				dprint ... snipsnap not running
				exit 0
			else
				dprint ... snipnsnap processes $pids found
				exit 1
			fi
		fi
		# This returns 0 if program OK and snipsnap down, and
		# returns 1 if program OK and snipsnap running
		runstate=`snipsnapstatus`
		exit $runstate
		;;
-stop|stop)	dprint stopping
		# if running stop
		runstate=`snipsnapstatus`
		case $runstate in
		0)	# Its down
		      	dprint stop requested, already down 
		      	;;
		1)    	# Its running
#                         Should I chnage this to a kill command.
			snipsnapadmin shutdown
		      	exit ;;
                esac ;;
-abort|abort)	: # This uses a kill and should not be used unless the stop
		#   method fails, it could easily be redesigned  to provide 
		#   different signals, using the shift and kill $1 idiom
		toppid=`showpids -top`
		kill $toppid
		dprint $toppid killed
		exit ;;
*)		echo invalid command line at command interpreter statement
		exit 900 ;;
esac

