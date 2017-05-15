#!/bin/sh

# name:              mark.sh
# description:       provides interface to work with temporary and named marks
#                     * marks current directory as temp mark or named mark
#                     * changes current directory by specified mark
#                     * lists all named marks
#                     * deletes specified named mark
# script maintainer: Andrey Bova
#
# last update:       May 15th 2017
# note:              to make the script works it's necessary to 
#                    run in such way: . ./mark.sh
#                    for efficient work make aliases:
#                      alias mark=". $SOME_PATH/mark.sh"
#                      alias goto=". $SOME_PATH/mark.sh goto"
#                    or replace it with functions.   

#Copyright (c) 2017 Andrey Bova
#License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
#This is free software: you are free to change and redistribute it.
#There is NO WARRANTY, to the extent permitted by law.

MLIST=$HOME/.marks
MTEMP=/tmp/__current_mark__

[ $# -eq 0 ] && pwd > $MTEMP 
case $1 in
    go  )  [ -z "$2" ] && MPATH=`tail -1 $MTEMP`
           [ -n "$2" ] && MPATH=`sed -ne "s/$2=\(.*\)/\1/p" $MLIST`
           cd $MPATH              ;;
    list) cat $MLIST              ;;
    rm  ) sed -i "/^$2=/d" $MLIST ;;
    *)    echo $1=`pwd` >> $MLIST ;;
esac
unset MLIST MTEMP MPATH

