#!/bin/sh

##################################################################################
#                                                                                #
# jes-launcher.sh                                                                #
#                                                                                #
# A shell script for launching JES on Mac OS X.                                  #
# Part of it is based on Tobias Fischer's Universal Java Application Stub,       #
# but it has been heavily specialized to JES.                                    #
#                                                                                #
#       https://github.com/tofi86/universalJavaApplicationStub                   #
#                                                                                #
##################################################################################
# Tobias' license:                                                               #
#                                                                                #
# The MIT License (MIT)                                                          #
#                                                                                #
# Copyright (c) 2014 Tobias Fischer                                              #
#                                                                                #
# Permission is hereby granted, free of charge, to any person obtaining a copy   #
# of this software and associated documentation files (the "Software"), to deal  #
# in the Software without restriction, including without limitation the rights   #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      #
# copies of the Software, and to permit persons to whom the Software is          #
# furnished to do so, subject to the following conditions:                       #
#                                                                                #
# The above copyright notice and this permission notice shall be included in all #
# copies or substantial portions of the Software.                                #
#                                                                                #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  #
# SOFTWARE.                                                                      #
#                                                                                #
##################################################################################


# Resolve symlinks.

PRG=$0

while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
    if expr "$link" : '^/' 2> /dev/null >/dev/null; then
        PRG="$link"
    else
        PRG="`dirname "$PRG"`/$link"
    fi
done


# Identify things in the bundle.

ContentsMacOS=`dirname "$PRG"`
Contents=`dirname "$ContentsMacOS"`

JES_BASE="$Contents/Resources/Java"
JES_HOME="$JES_BASE/jes"

InfoPlistFile="$Contents/Info.plist"

# read the program name from CFBundleName
CFBundleName=`/usr/libexec/PlistBuddy -c "print :CFBundleName" ${InfoPlistFile}`

# read the icon file name
CFBundleIconFile=`/usr/libexec/PlistBuddy -c "print :CFBundleIconFile" ${InfoPlistFile}`


# Identify our code.

JARS="$JES_BASE/dependencies/jars"

CLASSPATH="$JES_HOME/classes.jar"

CLASSPATH="$CLASSPATH:$JARS/jython-2.5.3.jar"
CLASSPATH="$CLASSPATH:$JARS/junit.jar"
CLASSPATH="$CLASSPATH:$JARS/jmf.jar"
CLASSPATH="$CLASSPATH:$JARS/jl1.0.jar"
CLASSPATH="$CLASSPATH:$JARS/AVIDemo.jar"

PYTHONHOME="$JES_BASE/dependencies/jython"

PYTHONPATH="$JES_HOME/python"


# Where should the Jython cache live?

PYTHONCACHE="$HOME/.cache/jes/jython-cache"
mkdir -p $PYTHONCACHE


# What about JESConfig.properties?

JESCONFIG="$HOME/Library/Application Support/JES/JESConfig.properties"
mkdir -p "$(dirname "$JESCONFIG")"


# Discover Java.

# first check system variable "$JAVA_HOME"
if [ -n "$JAVA_HOME" ]; then
	JAVACMD="$JAVA_HOME/bin/java"

# otherwise check "/usr/libexec/java_home" symlinks
elif [ -x /usr/libexec/java_home ]; then
	JAVACMD="`/usr/libexec/java_home`/bin/java"

# otherwise check Java standard symlink (old Apple Java)
elif test -h /Library/Java/Home; then
	JAVACMD="/Library/Java/Home/bin/java"

# fallback: public JRE plugin (Oracle Java)
else
	JAVACMD="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java"
fi


# Launch Java.
if [ -x "$JAVACMD" ]; then
	# enable drag & drop to the dock icon
	export CFProcessPath="$0"

	# execute Java and set
	#	- classpath
	#	- dock icon
	#	- application name
	#	- JVM options
	#	- JVM default options
	#	- main class
	#	- JVM arguments
    exec "$JAVACMD" \
        -classpath "$CLASSPATH" \
	    -Xdock:icon="$CONTENTS/Resources/${CFBundleIconFile}" \
	    -Dapple.laf.useScreenMenuBar=true \
	    -Xdock:name="${CFBundleName}" \
        ${JAVA_MEMORY:--Xmx512m} \
        -Djes.home="$JES_HOME" \
        -Djes.configfile="$JESCONFIG" \
        -Dpython.home="$PYTHONHOME" \
        -Dpython.path="$PYTHONPATH" \
        -Dpython.cachedir="$PYTHONCACHE" \
        JESstartup "$@"

else
	# display error message with applescript
	osascript -e "tell application \"System Events\" to display dialog \"Error launching ${CFBundleName}!\n\nYou need to have Java installed on your Mac!\nVisit http://java.com for more information.\" with title \"${CFBundleName}\" buttons {\"OK\"} default button 1 with icon path to resource \"${CFBundleIconFile}\" in bundle (path to me)"

	# exit with error
	exit 1
fi
