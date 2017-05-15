#!/bin/sh

# name:              psearch.sh
# description:       searchs files by privileges for specified user
# script maintainer: Andrey Bova
#
# last update:       May 15th 2017

#Copyright (c) 2017 Andrey Bova
#License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
#This is free software: you are free to change and redistribute it.
#There is NO WARRANTY, to the extent permitted by law.

panic() { 
    echo $* >&2; exit 42;
}

check_dir() {
    dir="$1";
    ls "$dir" | grep "." 1>/dev/null 2>&1 || return
    flist="$dir/*"; [ -n "$hidden" ] && flist="$flist $dir/.*"
    for file in $flist; do
        [ -d "$file" -a -n "$recursive" -a $2 -lt $MAX_DEPTH ] && {
            check_dir "$file" `expr $2 + 1`
        }
        ls -ld "$file" | (
            read mode links owner group other
            [ "x$usr" = "x$owner" ]                      && is_owner=true
            groups "$usr" | grep "\<$group\>" >/dev/null && in_group=true
            [ -z "$is_owner" -a -z "$in_group" ]         && is_other=true
            echo $mode | sed 's/\(.\)/\1 /g' | (
                read type ur uw ux gr gw gx or ow ox sticky

                [ -n "$TYPE" -a "$type" != "$TYPE" ] && continue

                unset u g o
                case "$MODE" in 
                    r)
                        [ "$ur" = "r" ] && u=true
                        [ "$gr" = "r" ] && g=true
                        [ "$or" = "r" ] && o=true
                        ;;
                    w)
                        [ "$uw" = "w" ] && u=true
                        [ "$gw" = "w" ] && g=true
                        [ "$ow" = "w" ] && o=true
                        ;;
                    x) 
                        [ "$ux" = "x" -o "$ux" = "s" ] && u=true
                        [ "$gx" = "x" -o "$ux" = "s" ] && g=true
                        [ "$ox" = "x" ] && o=true
                        ;;
                esac
                
                if [ -n "$u" ]; then
                    [ -n "$is_owner" ] && echo "$file" && continue    
                    if [ -n "$g" ]; then 
                        [ -n "$in_group" ] && echo "$file" && continue
                    else 
                        [ -n "$in_group" ] && continue
                    fi
                    [ -n "$o" -a -n "$is_other" ] && echo "$file"
                else
                    [ -n "$is_owner" ] && continue

                    if [ -n "$g" ]; then
                        [ -n "$in_group" ] && echo "$file" && continue
                    else 
                        [ -n "$in_group" ] && continue
                    fi
                    [ -n "$o" -a -n "$is_other" ] && echo "$file"
                fi
            )
        )
    done
}

list_files_by_user() {
    while [ $# -gt 0 ]; do
        usr="$1"; shift
        getent passwd "$usr" 2>&1 1>/dev/null || {
            echo "psearch: $usr is invalid username"
            continue
        }
        echo "$usr:"
        check_dir "$BASEDIR" 1
    done
}

set_mode() {
    case $1 in
        r      ) MODE=r  ;;
        read   ) MODE=r  ;;
        w      ) MODE=w  ;;
        write  ) MODE=w  ;;
        x      ) MODE=x  ;;
        execute) MODE=x  ;;
        *      ) usage 4 ;;
    esac
}

set_type() {
    case $1 in
        a                     ) unset TYPE ;;
        all                   ) unset TYPE ;;
        r                     ) TYPE=r     ;;
        regular               ) TYPE=r     ;;
        d                     ) TYPE=d     ;;
        directory             ) TYPE=d     ;;
        l                     ) TYPE=l     ;;
        symbolic-link         ) TYPE=l     ;;
        b                     ) TYPE=b     ;; 
        block-special-file    ) TYPE=b     ;; 
        c                     ) TYPE=c     ;;
        character-special-file) TYPE=c     ;;
        p                     ) TYPE=p     ;;
        pipe                  ) TYPE=p     ;;
        s                     ) TYPE=s     ;;
        socket                ) TYPE=s     ;;
        *                     ) usage 2    ;;
    esac
}

set_dir() {
    [ -d $1 ] || panic "psearch: $1 isn't directory"
    BASEDIR=`cd $1 2>/dev/null || panic "psearch: $1 cannot be used"; pwd -P`
}

version() {
    echo "psearch(Privilege search) 1.0
Copyright (C) 2017 Andrey Bova

License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
"
    exit 0
}

usage() {
    echo "psearch: search by privileges version 1.0 
    -m, --mode MODE set privilege mode to search, read by default
        available mode:
        * r(read)
        * w(write)
        * x(execute)
    -t, --type TYPE set file type to search, all files by default
        available types:
        * a(all)
        * r(regular)
        * d(directory)
        * l(symbolic-link)
        * b(block-special-file)
        * c(character-special-file)
        * p(pipe)
        * s(socket)
    -d, --dir DIR   set DIR as search-start directory 
    -a, --all       search hidden files too
    -r, --recursive recursive search files
    -h, --help      print this help   
    -v, --version   print the version of this program

    --max-depth DEPTH set max depth for recursive descent"
    exit $1
}

[ $# -eq 0 ] && panic no args
unset is_onwer in_group MODE TYPE MAX_DEPTH recursive hidden

for arg in "$@"; do
    shift; [ -n "$SKIP_NEXT" ] && unset SKIP_NEXT && continue
    case "$arg" in 
        "--all"      ) set -- "$@" "-a" ;;
        "--mode"     ) set -- "$@" "-m" ;; 
        "--type"     ) set -- "$@" "-t" ;; 
        "--recursive") set -- "$@" "-r" ;;
        "--version"  ) set -- "$@" "-v" ;; 
        "--help"     ) set -- "$@" "-h" ;; 
        "--dir"      ) set -- "$@" "-d" ;;

        "--max-depth") depth=$1;
                       case "$depth" in 
                          ''|*[!0-9]*) usage 2 ;;
                       esac
                       [ $depth -eq 0 ] && usage 2
                       MAX_DEPTH=$depth
                       SKIP_NEXT=TRUE
                       ;;
        *) set -- "$@" "$arg"
    esac
done


while getopts ":vahrd:m:t:" opt; do
    case $opt in
         a) hidden=true       ;;
         m) set_mode $OPTARG  ;;
         t) set_type $OPTARG  ;;
         d) set_dir  $OPTARG  ;;
         r) recursive=true    ;;
         v) version           ;;
         h) usage 0           ;;
        \?) usage 2           ;;
    esac
done

shift `expr $OPTIND - 1`
PWD=`pwd -P`
MODE=${MODE:-'r'}
MAX_DEPTH=${MAX_DEPTH:-'9999'}
BASEDIR=${BASEDIR:-$PWD}

list_files_by_user $*
