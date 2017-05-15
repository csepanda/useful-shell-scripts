#!/bin/sh

# name:              lcheck.sh
# description:       checks locked users on the host
# script maintainer: Andrey Bova
#
# last update:       April 1st 2017

#Copyright (c) 2017 Andrey Bova
#License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
#This is free software: you are free to change and redistribute it.
#There is NO WARRANTY, to the extent permitted by law.

IFS=":"

panic() { echo "$*" >&2; exit 42; }
verbose() { 
    VERBOSE_FLAG=TRUE 
    printf "%-20s %s\n" 'USERNAME' 'CAUSE';
}
contains() { 
    for shell in $2; do 
        [ "$1" = "$shell" ] && return 0; 
    done; 
    return 1; 
}

shadow() {
    time=`nawk 'BEGIN{print srand}'`
    [ -r /etc/shadow ] || panic lcheck\: Permission denied 
    while read username password lastchg min max warn inactive expire flag; do
        if [ x"$password" = 'x*LK*' ]; then
            printf "%-20s %s\n" $username ${VERBOSE_FLAG:+'password is locked'}
          elif [ $expire -le $time 2>/dev/null ]; then
            printf "%-20s %s\n" $username ${VERBOSE_FLAG:+'account is expired'}
        fi
    done < /etc/shadow | grep '.' || exit 1
    exit 0
}

passwd() {
    getent passwd | while read username hash uid guid info home sh; do
        [ $sh ] && [ -x $sh ] || printf "%-20s %s\n" $username ${VERBOSE_FLAG:+'shell is locked'}
    done | grep '.' || exit 1
    exit 0
}

usage() {
    echo "lcheck: locked user check version 1.0 
    -s, --shadow    locked users by password status or expiry date
    -p, --passwd    locked users by starting program defined in passwd
    -v, --verbose   print in verbose format
    -h, --help      print this help   
    -V, --version   print the version of this program"
    exit $1
}

version() {
    echo "lcheck: (lock check) 1.0
Copyright (C) 2017 Andrey Bova

License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
"
    exit 0
}

while getopts ":s(shadow):p(passwd):h(help):v(verbose):V(version)" opt; do
    case $opt in
         s) shadow                                  ;;
         p) passwd                                  ;;
         v) verbose                                 ;;
         V) version                                 ;;
         h) usage 0                                 ;;
        \?) usage 2                                 ;; 
    esac
done

passwd
