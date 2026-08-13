#!/bin/sh

export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o StrictHostKeyChecking=accept-new}"

PLATFORM=unknown
FLAVOR=unknown
PKG_MANAGER=unknown
if [ "$OS" = "Windows_NT" ]; then
    export HOME="${HOMEDRIVE}${HOMEPATH}"
    PLATFORM=win32
    FLAVOR=win64
    PKG_MANAGER=choco
else
    PLATFORM=$(uname 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if [ "$PLATFORM" = "linux" ] && [ -f /system/bin/adb ] &&
        getprop --help >/dev/null 2>&1; then
        PLATFORM=android
    fi
    if [ "$PLATFORM" = "linux" ]; then
        FLAVOR=$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]')
        if [ "$FLAVOR" = "" ]; then
            if [ -f /etc/redhat-release ]; then
                FLAVOR=rhel
            elif [ -f /etc/SuSE-release ]; then
                FLAVOR=suse
            elif [ -f /etc/debian_version ]; then
                FLAVOR=debian
            elif grep -qE '^ID=alpine$' /etc/os-release 2>/dev/null; then
                FLAVOR=alpine
            else
                FLAVOR=unknown
            fi
        fi
        case "$FLAVOR" in
        rhel)
            if command -v microdnf >/dev/null 2>&1; then
                PKG_MANAGER=microdnf
            elif command -v dnf >/dev/null 2>&1; then
                PKG_MANAGER=dnf
            else
                PKG_MANAGER=yum
            fi
            ;;
        suse) PKG_MANAGER=zypper ;;
        debian | ubuntu) PKG_MANAGER=apt-get ;;
        alpine) PKG_MANAGER=apk ;;
        arch | manjaro) PKG_MANAGER=pacman ;;
        esac
    elif [ "$PLATFORM" = "darwin" ]; then
        PKG_MANAGER=brew
    else
        case "$PLATFORM" in
        msys*)
            PLATFORM=win32
            FLAVOR=msys
            PKG_MANAGER=pacman
            ;;
        mingw*)
            PLATFORM=win32
            FLAVOR=msys
            PKG_MANAGER=mingw-get
            ;;
        cygwin*)
            PLATFORM=win32
            FLAVOR=cygwin
            ;;
        esac
    fi
fi
if [ "$FLAVOR" = "unknown" ]; then
    FLAVOR="$PLATFORM"
fi

_STATE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/dotstow"
_STOWED_PATH="$_STATE_PATH/stowed"
if [ "$DOTFILES_PATH" = "" ]; then
    DOTFILES_PATH="$_STATE_PATH/dotfiles"
fi

main() {
    _prepare
    case "$_COMMAND" in
    init) _init "$@" ;;
    stow) _stow "$@" ;;
    unstow) _unstow "$@" ;;
    wizard) _wizard ;;
    available) _available ;;
    stowed) _stowed ;;
    sync) _sync ;;
    path) _path ;;
    reset) _reset ;;
    status) _status ;;
    esac
}

_prepare() {
    if ! command -v stow >/dev/null 2>&1; then
        _SUDO=""
        if command -v sudo >/dev/null 2>&1; then
            _SUDO=sudo
        fi
        case "$PKG_MANAGER" in
        apt-get) $_SUDO apt-get install -y stow ;;
        brew) brew install stow ;;
        dnf | microdnf | yum) $_SUDO "$PKG_MANAGER" install -y stow ;;
        zypper) $_SUDO zypper install -y stow ;;
        apk) $_SUDO apk add --no-cache stow ;;
        pacman) $_SUDO pacman -S --noconfirm stow ;;
        *)
            echo "please install the stow command
    https://www.gnu.org/software/stow" >&2
            exit 1
            ;;
        esac
    fi
    mkdir -p "$_STATE_PATH"
    if [ ! -d "$DOTFILES_PATH" ] && [ "$_COMMAND" != "init" ]; then
        _init
    fi
}

_require_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        echo "please install the gum command
    https://github.com/charmbracelet/gum" >&2
        exit 1
    fi
}

get_package_dir() {
    for _GROUP in "$FLAVOR" "$PLATFORM" global; do
        if [ -d "$DOTFILES_PATH/$_GROUP/$1" ]; then
            printf '%s\n' "$DOTFILES_PATH/$_GROUP"
            return
        fi
    done
}

_init() {
    if [ -d "$DOTFILES_PATH" ]; then
        echo "dotfiles already initialized at $DOTFILES_PATH" >&2
        exit 1
    fi
    _REPO="$1"
    if [ "$_REPO" = "" ]; then
        _require_gum
        _REPO=$(gum input --value "git@gitlab.com:$USER/dotfiles" \
            --prompt "select the git repository that contains your dotfiles: ")
    fi
    if [ "$_REPO" = "" ]; then
        echo "no repo specified" >&2
        exit 1
    fi
    echo '$ git clone '"$_REPO $DOTFILES_PATH"
    git clone "$_REPO" "$DOTFILES_PATH" || exit 1
    if [ ! -e "$HOME/.dotfiles" ] && [ ! -L "$HOME/.dotfiles" ]; then
        ln -s "$DOTFILES_PATH" "$HOME/.dotfiles"
    fi
}

_stow() {
    _PACKAGE="$1"
    shift
    _PACKAGE_DIR=$(get_package_dir "$_PACKAGE")
    if [ "$_PACKAGE_DIR" = "" ]; then
        echo "package $_PACKAGE not found" >&2
        exit 1
    fi
    echo "stowing $_PACKAGE package for $FLAVOR $PLATFORM"
    _DOTFILES_PHYS=$(cd -P "$DOTFILES_PATH" && pwd)
    _PACKAGE_PHYS=$(cd -P "$_PACKAGE_DIR/$_PACKAGE" && pwd)
    # remove targets that would block stow (regular files or foreign
    # symlinks), but never anything that already resolves into the
    # dotfiles repo
    (cd "$_PACKAGE_DIR/$_PACKAGE" && find . -type f) | sed 's|^\./||' |
        while IFS= read -r _FILE; do
            _TARGET="$HOME/$_FILE"
            if [ ! -f "$_TARGET" ] && [ ! -L "$_TARGET" ]; then
                continue
            fi
            # a parent directory resolving into the repo means a previous
            # stow folded it into a directory symlink; deleting through it
            # would destroy repo files, and stow can split folded trees on
            # its own
            _PARENT_PHYS=$(cd -P "$(dirname "$_TARGET")" 2>/dev/null && pwd)
            case "$_PARENT_PHYS/" in
            "$_DOTFILES_PHYS"/*) continue ;;
            esac
            if [ -L "$_TARGET" ]; then
                _DEST=$(readlink "$_TARGET")
                case "$_DEST" in
                /*) ;;
                *) _DEST="$(dirname "$_TARGET")/$_DEST" ;;
                esac
                _DEST_PHYS=$(cd -P "$(dirname "$_DEST")" 2>/dev/null && pwd)
                case "$_DEST_PHYS/" in
                "$_PACKAGE_PHYS"/*) continue ;;
                esac
            fi
            echo '$ rm -f '"$_TARGET"
            rm -f "$_TARGET"
        done
    echo '$ '"stow -t $HOME -d $_PACKAGE_DIR $* $_PACKAGE" | tr -s ' '
    stow -t "$HOME" -d "$_PACKAGE_DIR" "$@" "$_PACKAGE" || exit 1
    mkdir -p "$_STOWED_PATH/$_PACKAGE"
}

_unstow() {
    _PACKAGE="$1"
    shift
    _PACKAGE_DIR=$(get_package_dir "$_PACKAGE")
    if [ "$_PACKAGE_DIR" = "" ]; then
        echo "package $_PACKAGE not found" >&2
        exit 1
    fi
    echo "unstowing $_PACKAGE package for $FLAVOR $PLATFORM"
    echo '$ '"stow -t $HOME -d $_PACKAGE_DIR -D $* $_PACKAGE" | tr -s ' '
    stow -t "$HOME" -d "$_PACKAGE_DIR" -D "$@" "$_PACKAGE" || exit 1
    rm -rf "${_STOWED_PATH:?}/$_PACKAGE"
}

_available() {
    for _GROUP in global "$FLAVOR" "$PLATFORM"; do
        ls "$DOTFILES_PATH/$_GROUP" 2>/dev/null
    done | sort -u
}

_stowed() {
    ls "$_STOWED_PATH" 2>/dev/null | sort -u
}

_sync() {
    if [ ! -d "$DOTFILES_PATH" ]; then
        echo "dotfiles not initialized" >&2
        exit 1
    fi
    cd "$DOTFILES_PATH" || exit 1
    if [ "$(git status --porcelain)" != "" ]; then
        _CHANGED=$(git status --porcelain | head -n1 | cut -c4-)
        echo '$ git add -A'
        git add -A
        echo '$ git commit -m "Updated '"$_CHANGED"'"'
        git commit -m "Updated $_CHANGED"
    fi
    echo '$ git pull'
    git pull || exit 1
    echo '$ git push'
    git push
}

_wizard() {
    _require_gum
    _STOWED=$(_stowed)
    _NOT_STOWED=$( (_stowed && _available) | sort | uniq -u)
    _PACKAGES_UNSTOW=""
    _PACKAGES_STOW=""
    if [ "$_STOWED" != "" ]; then
        _PACKAGES_UNSTOW=$(gum choose --no-limit \
            --header "select the packages you wish to unstow" $_STOWED)
    fi
    if [ "$_NOT_STOWED" != "" ]; then
        _PACKAGES_STOW=$(gum choose --no-limit \
            --header "select the packages you wish to stow" $_NOT_STOWED)
    fi
    if [ "$_PACKAGES_UNSTOW" != "" ]; then
        if ! gum confirm "$(printf 'UNSTOW PACKAGES\n\n%s' "$_PACKAGES_UNSTOW")"; then
            exit 1
        fi
    fi
    if [ "$_PACKAGES_STOW" != "" ]; then
        if ! gum confirm "$(printf 'STOW PACKAGES\n\n%s' "$_PACKAGES_STOW")"; then
            exit 1
        fi
    fi
    for _P in $_PACKAGES_UNSTOW; do
        echo '$ dotstow unstow '"$_P"
        _unstow "$_P"
    done
    for _P in $_PACKAGES_STOW; do
        echo '$ dotstow stow '"$_P"
        _stow "$_P"
    done
}

_path() {
    echo "$DOTFILES_PATH"
}

_reset() {
    cd "$DOTFILES_PATH" || exit 1
    echo '$ git add -A'
    git add -A
    echo '$ git reset --hard'
    git reset --hard
}

_status() {
    cd "$DOTFILES_PATH" || exit 1
    git status
}

if ! test $# -gt 0; then
    set -- "-h"
fi

while test $# -gt 0; do
    case "$1" in
    -h | --help)
        echo "dotstow - manage dotfiles with git and stow"
        echo " "
        echo "dotstow [options] command <PACKAGE>"
        echo " "
        echo "options:"
        echo "    -h, --help            show brief help"
        echo " "
        echo "commands:"
        echo "    init <REPO>            initialize dotstow"
        echo "    s, stow <PACKAGE>      stow a package"
        echo "    u, unstow <PACKAGE>    unstow a package"
        echo "    w, wizard              dotfiles wizard"
        echo "    a, available           available packages"
        echo "    stowed                 stowed packages"
        echo "    sync                   sync dotfiles"
        echo "    status                 dotfiles git status"
        echo "    reset                  reset dotfiles"
        echo "    path                   get dotfiles path"
        exit 0
        ;;
    -*)
        echo "invalid option $1" >&2
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
    _COMMAND=init
    ;;
s | stow)
    shift
    if ! test $# -gt 0; then
        echo "no package specified" >&2
        exit 1
    fi
    _COMMAND=stow
    ;;
u | unstow)
    shift
    if ! test $# -gt 0; then
        echo "no package specified" >&2
        exit 1
    fi
    _COMMAND=unstow
    ;;
w | wizard)
    shift
    _COMMAND=wizard
    ;;
a | available)
    shift
    _COMMAND=available
    ;;
stowed)
    shift
    _COMMAND=stowed
    ;;
sync)
    shift
    _COMMAND=sync
    ;;
path)
    shift
    _COMMAND=path
    ;;
reset)
    shift
    _COMMAND=reset
    ;;
status)
    shift
    _COMMAND=status
    ;;
*)
    echo "invalid command $1" >&2
    exit 1
    ;;
esac

main "$@"
