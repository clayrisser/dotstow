#!/bin/sh

export _STATE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/dotstow"
export _STOWED_PATH="$_STATE_PATH/stowed"
if [ "$DOTFILES_PATH" = "" ]; then
    export DOTFILES_PATH="$_STATE_PATH/dotfiles"
fi

export ARCH=unknown
export FLAVOR=unknown
export PKG_MANAGER=unknown
export PLATFORM=unknown
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
    _prepare
    if [ "$_COMMAND" = "init" ]; then
        _init $@
    elif [ "$_COMMAND" = "stow" ]; then
        _stow $@
    elif [ "$_COMMAND" = "unstow" ]; then
        _unstow $@
    elif [ "$_COMMAND" = "available" ]; then
        _available $@
    elif [ "$_COMMAND" = "sync" ]; then
        _sync $@
    elif [ "$_COMMAND" = "stowed" ]; then
        _stowed $@
    fi
}

_prepare() {
    if ! which stow 2>&1 >/dev/null; then
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            sudo apt-get install -y stow
        else
            echo "please install the stow command
    https://www.gnu.org/software/stow" >&2
        exit 1
        fi
    fi
    if [ ! -d "$_STATE_PATH" ]; then
        mkdir -p "$_STATE_PATH"
    fi
}

_init() {
    _REPO=$1
    if [ -d "$DOTFILES_PATH" ]; then
        echo "dotfiles already initialized" >&2
        exit 1
    fi
    echo '$ git clone '"$_REPO $DOTFILES_PATH"
    git clone $_REPO "$DOTFILES_PATH"
    if [ ! -L "$HOME/.dotfiles" ] && [ ! -d "$HOME/.dotfiles" ] && [ ! -f "$HOME/.dotfiles" ]; then
        ln -s "$DOTFILES_PATH" "$HOME/.dotfiles"
    fi
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
    if [ "$_RM_FILES" != "" ]; then
        echo '$ rm -f '"$_RM_FILES"
        rm -f $_RM_FILES
    fi
    echo '$ '"stow -t $HOME -d $_PACKAGE_DIR $@ $_PACKAGE" | sed 's| \+| |g'
    stow --override '/.*/s' -t $HOME -d $_PACKAGE_DIR $@ $_PACKAGE
    mkdir -p "$_STOWED_PATH/$_PACKAGE"
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
    rm -rf "$_STOWED_PATH/$_PACKAGE"
}

_available() {
    ((ls $DOTFILES_PATH/global 2>/dev/null || true) && \
        (ls $DOTFILES_PATH/$FLAVOR 2>/dev/null || true) && \
        (ls $DOTFILES_PATH/$PLATFORM 2>/dev/null || true)) | sort | uniq
}

_stowed() {
    (ls $_STOWED_PATH 2>/dev/null || true) | sort | uniq
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
            echo "    init <REPO>         initialize dotstow"
            echo "    s, stow <PACKAGE>      stow a package"
            echo "    u, unstow <PACKAGE>    unstow a package"
            echo "    a, available           available packages"
            echo "    stowed                 stowed packages"
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
    init)
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
    a|available)
        shift
        export _COMMAND=available
    ;;
    stowed)
        shift
        export _COMMAND=stowed
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
