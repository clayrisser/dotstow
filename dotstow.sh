#!/bin/sh

if ! test $# -gt 0; then
    set -- "-h"
fi

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo "dotstow - manage dotfiles with stow and make"
            echo " "
            echo "dotstow [options] command <PACKAGE>"
            echo " "
            echo "options:"
            echo "    -h, --help            show brief help"
            echo " "
            echo "commands:"
            echo "    stow <INSTALLER>      stow a package"
            echo "    unstow <INSTALLER>    unstow a package"
            exit 0
        ;;
        -*)
            echo "invalid option $1" 1>&2
            exit 1
        ;;
        *)
            break
        ;;
    esac
done

case "$1" in
    i|install)
        shift
        if test $# -gt 0; then
            export _INSTALL=1
            export _INSTALLER=$1
        else
            echo "no installer specified" 1>&2
            exit 1
        fi
        shift
    ;;
    u|uninstall)
        shift
        if test $# -gt 0; then
            export _UNINSTALL=1
            export _INSTALLER=$1
        else
            echo "no installer specified" 1>&2
            exit 1
        fi
        shift
    ;;
    reinstall)
        shift
        if test $# -gt 0; then
            export _REINSTALL=1
            export _INSTALLER=$1
        else
            echo "no installer specified" 1>&2
            exit 1
        fi
        shift
    ;;
    d|dependencies)
        shift
        if test $# -gt 0; then
            export _DEPENDENCIES=1
            export _INSTALLER=$1
        else
            echo "no installer specified" 1>&2
            exit 1
        fi
        shift
    ;;
    a|available)
        shift
        export _AVAILABLE=1
    ;;
    installed)
        shift
        export _INSTALLED=1
    ;;
    *)
        echo "invalid command $1" 1>&2
        exit 1
    ;;
esac

main
