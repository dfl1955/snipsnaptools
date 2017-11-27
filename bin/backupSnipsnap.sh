#!/bin/sh

#####################################################################
#
# backupSnipsnap.sh .... this script backsup a snipsnap instance
#
Pver=1.6 
Pname=$0 
USAGE="$0 [-help|-version|-prod]"

#####################################################################
#
#  Author: Dave Levy
#  Licence : CC - BY-SA
#
SnipsnapHost="http://localhost:8668/"
if [ $# != 0 ]
then
	case $1 in
	-?|-help|--help)  echo $USAGE ; exit ;;
	-version)	echo $Pname $Pver ; exit ;;
	-prod)		HostAlias="davelevy.dyndns.info" 
			# this branch allows a hostname override
			# Host alias is used in the dump name
			# now a bit crap this instamce no longer exists
			SnipsnapHost="http://davelevy.dyndns.info:8668/"
			;;
	*)		echo Error $USAGE exit ;;
	esac
fi

print()
{ 
	echo $Pname $Pver $*
}

# This might not be too bright, i.e. some shells don't like a function
# named print and at least on one box I had a problem with this.

print ... starts @ `date`
#
# Ver 1.6 - backup directory moved to ~config, function uniquefn used
# Ver 1.5 - amended for the ubuntu build
# Ver 1.4 - placed a date command in the first and lasr display to allow
#	    the duration to be measured

. /home/snipsnap/bin/functions

#####################################################################
#
#  This the default config. i.e. the local host
#
HostAlias=$(getconfigval EXPORT_PFX)  # Host alias is used in the dump name
JAVA_HOME=$( getconfigval JAVA_HOME )
PATH=${PATH}:${JAVA_HOME}/bin
export JAVA_HOME PATH

# This needs to run as the Snipsnap user

print snipsnap host is ${SnipsnapHost} aliased as ${HostAlias}

jpasswd=$(cat ${HOME}/etc/.token)
BackupFileDirectory=$( getconfigval BACKUPS )
ExecutionDirectory=${HOME}

if [ ! -d ${BackupFileDirectory} ]
then
    print Error No backup directory ${BackupFileDirectory}
    exit 100
fi

wholefn=$(uniquefn "${BackupFileDirectory}/${HostAlias}-$(date +%Y%m%d)-dmp" \
		xml)
print backup file name is ${wholefn}

cd ${ExecutionDirectory}

# John forced the classpath and verbose by using the -classpath ${CLASSPATH}
#   and the -verbose parameter. I removed it at V1.1


JAVA_OPTS="$JAVA_OPTS -Xsqnopause -XX:+UseLWPSynchronization -Xms512m -Xmx1024m -Xss256k -XX:MaxNewSize=96m -XX:MaxPermSize=512m"
java  $JAVA_OPTS \
	-jar lib/snipsnap-utils.jar \
	-url ${SnipsnapHost} \
	-user "boss" -password ${jpasswd} \
	snipSnap.dumpXml > ${wholefn}  


print ... ends @ `date`
