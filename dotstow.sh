#!/bin/sh

export ARCH=unknown
export FLAVOR=unknown
export PKG_MANAGER=unknown
export PLATFORM=unknown

if [ "$DOTFILES_PATH" = "" ]; then
    export DOTFILES_PATH="$HOME/.dotfiles"
fi

if [ "$OS" = "Windows_NT" ]; then
	export HOME="${HOMEDRIVE}${HOMEPATH}"
	PLATFORM=win32
	FLAVOR=win64
	ARCH="$PROCESSOR_ARCHITECTURE"
	PKG_MANAGER=choco
    if [ "$ARCH" = "AMD64" ]; then
		ARCH=amd64
    elif [ "$ARCH" = "ARM64" ]; then
		ARCH=arm64
    fi
    if [ "$PROCESSOR_ARCHITECTURE" = "x86" ]; then
		ARCH=amd64
        if [ "$PROCESSOR_ARCHITEW6432" = "" ]; then
			ARCH=x86
			FLAVOR=win32
        fi
    fi
else
	PLATFORM=$(uname 2>/dev/null | tr '[:upper:]' '[:lower:]' 2>/dev/null)
	ARCH=$( ( dpkg --print-architecture 2>/dev/null || uname -m 2>/dev/null || arch 2>/dev/null || echo unknown) | \
        tr '[:upper:]' '[:lower:]' 2>/dev/null)
    if [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ]; then
		ARCH=386
    elif [ "$ARCH" = "x86_64" ]; then
		ARCH=amd64
    fi
	if [ "$PLATFORM" = "linux" ]; then
        if [ -f /system/bin/adb ]; then
            if [ "$(getprop --help >/dev/null 2>/dev/null && echo 1 || echo 0)" = "1" ]; then
                PLATFORM=android
            fi
        fi
        if [ "$PLATFORM" = "linux" ]; then
            FLAVOR=$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]' 2>/dev/null)
            if [ "$FLAVOR" = "" ]; then
                FLAVOR=unknown
                if [ -f /etc/redhat-release ]; then
                    FLAVOR=rhel
                elif [ -f /etc/SuSE-release ]; then
                    FLAVOR=suse
                elif [ -f /etc/debian_version ]; then
                    FLAVOR=debian
                elif (cat /etc/os-release 2>/dev/null | grep -qE '^ID=alpine$'); then
                    FLAVOR=alpine
                fi
            fi
            if [ "$FLAVOR" = "rhel" ]; then
				PKG_MANAGER=yum
            elif [ "$FLAVOR" = "suse" ]; then
				PKG_MANAGER=zypper
            elif [ "$FLAVOR" = "debian" ]; then
				PKG_MANAGER=apt-get
            elif [ "$FLAVOR" = "ubuntu" ]; then
				PKG_MANAGER=apt-get
            elif [ "$FLAVOR" = "alpine" ]; then
				PKG_MANAGER=apk
            fi
        fi
	elif [ "$PLATFORM" = "darwin" ]; then
		PKG_MANAGER=brew
    else
        if (echo "$PLATFORM" | grep -q 'MSYS'); then
			PLATFORM=win32
			FLAVOR=msys
			PKG_MANAGER=pacman
        elif (echo "$PLATFORM" | grep -q 'MINGW'); then
			PLATFORM=win32
			FLAVOR=msys
			PKG_MANAGER=mingw-get
        elif (echo "$PLATFORM" | grep -q 'CYGWIN'); then
			PLATFORM=win32
			FLAVOR=cygwin
        fi
    fi
fi

get_package_dir() {
    _PACKAGE=$1
    cd $DOTFILES_PATH
    _PACKAGE_GROUP=$( ((ls $FLAVOR 2>/dev/null || true) | grep -qE "^${_PACKAGE}$") && echo $FLAVOR || \
        (((ls $PLATFORM 2>/dev/null || true) | grep -qE "^${_PACKAGE}$") && echo $PLATFORM || \
            (((ls global 2>/dev/null || true) | grep -qE "^${_PACKAGE}$") && echo global || true)) )
    if [ "$_PACKAGE_GROUP" != "" ] && [ -d "$_PACKAGE_GROUP" ]; then
        cd $_PACKAGE_GROUP
        pwd
    fi
}

main() {
    if [ "$_COMMAND" = "init" ]; then
        _init $@
    elif [ "$_COMMAND" = "stow" ]; then
        _stow $@
    elif [ "$_COMMAND" = "unstow" ]; then
        _unstow $@
    elif [ "$_COMMAND" = "sync" ]; then
        _sync $@
    fi
}

_init() {
    _REPO=$1
    if [ -d "$DOTFILES_PATH" ]; then
        echo "dotfiles already initialized" >&2
        exit 1
    fi
    echo '$ git clone '"$_REPO $DOTFILES_PATH"
    git clone $_REPO $DOTFILES_PATH
}

_stow() {
    _PACKAGE=$1
    shift
    _PACKAGE_DIR=$(get_package_dir $_PACKAGE)
    echo "stowing $_PACKAGE package for $FLAVOR $PLATFORM"
    if [ "$_PACKAGE_DIR" = "" ]; then
        echo "package $_PACKAGE not found" >&2
        exit 1
    fi
    _RM_FILES=$(echo $(for f in $(cd $_PACKAGE_DIR/$_PACKAGE && (find . -type f | sed "s|^./|$HOME/|g")); do \
        if [ -f $f ]; then echo $f; fi \
    done))
    echo '$ rm -f '"$_RM_FILES"
    rm -f $_RM_FILES
    echo '$ '"stow -t $HOME -d $_PACKAGE_DIR $@ $_PACKAGE" | sed 's| \+| |g'
    stow -t $HOME -d $_PACKAGE_DIR $@ $_PACKAGE
}

_unstow() {
    _PACKAGE=$1
    shift
    _PACKAGE_DIR=$(get_package_dir $_PACKAGE)
    echo "unstowing $_PACKAGE package for $FLAVOR $PLATFORM"
    if [ "$_PACKAGE_DIR" = "" ]; then
        echo "package $_PACKAGE not found" >&2
        exit 1
    fi
    echo '$ '"stow -t $HOME -d $_PACKAGE_DIR -D $@ $_PACKAGE" | sed 's| \+| |g'
    stow -t $HOME -d $_PACKAGE_DIR -D $@ $_PACKAGE
}

_sync() {
    cd $DOTFILES_PATH
    echo '$ git add -A'
    git add -A
    echo '$ git commit -m "Updated '"$(git status | grep 'modified: ' | sed 's|^.*modified:\s*||g' | head -n1)"'"'
    git commit -m "Updated $(git status | grep 'modified: ' | sed 's|^.*modified:\s*||g' | head -n1)"
    echo '$ git pull'
    git pull
    echo '$ git push'
    git push
}

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
            echo "    i, init <REPO>         initialize dotstow"
            echo "    s, stow <PACKAGE>      stow a package"
            echo "    u, unstow <PACKAGE>    unstow a package"
            echo "    sync                   sync dotfiles"
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
    i|init)
        shift
        if test $# -gt 0; then
            export _COMMAND=init
        else
            echo "no repo specified" 1>&2
            exit 1
        fi
    ;;
    s|stow)
        shift
        if test $# -gt 0; then
            export _COMMAND=stow
        else
            echo "no package specified" 1>&2
            exit 1
        fi
    ;;
    u|unstow)
        shift
        if test $# -gt 0; then
            export _COMMAND=unstow
        else
            echo "no package specified" 1>&2
            exit 1
        fi
    ;;
    sync)
        shift
        export _COMMAND=sync
    ;;
    *)
        echo "invalid command $1" 1>&2
        exit 1
    ;;
esac

main $@
