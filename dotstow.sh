#!/bin/sh

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-gnome}
export _TMP_PATH="${XDG_RUNTIME_DIR:-$([ -d "/run/user/$(id -u $USER)" ] && echo "/run/user/$(id -u $USER)" || echo ${TMP:-${TEMP:-/tmp}})}/cody/wizard/$$"
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
    ARCH=$( (dpkg --print-architecture 2>/dev/null || uname -m 2>/dev/null || arch 2>/dev/null || echo unknown) |
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
                PKG_MANAGER=$(which microdnf >/dev/null 2>&1 && echo microdnf ||
                    echo $(which dnf >/dev/null 2>&1 && echo dnf || echo yum))
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
if [ "$FLAVOR" = "unknown" ]; then
    FLAVOR="$PLATFORM"
fi

get_package_dir() {
    _PACKAGE=$1
    cd $DOTFILES_PATH
    _PACKAGE_GROUP=$( ( (ls $FLAVOR 2>/dev/null || true) | grep -qE "^${_PACKAGE}$") && echo $FLAVOR ||
        ( ( (ls $PLATFORM 2>/dev/null || true) | grep -qE "^${_PACKAGE}$") && echo $PLATFORM ||
            ( ( (ls global 2>/dev/null || true) | grep -qE "^${_PACKAGE}$") && echo global || true)))
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
    elif [ "$_COMMAND" = "wizard" ]; then
        _wizard $@
    elif [ "$_COMMAND" = "path" ]; then
        _path $@
    elif [ "$_COMMAND" = "reset" ]; then
        _reset $@
    elif [ "$_COMMAND" = "status" ]; then
        _status $@
    fi
}

_prepare() {
    if ! which stow 2>&1 >/dev/null; then
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            sudo apt-get install -y stow
        elif [ "$PKG_MANAGER" = "brew" ]; then
            brew install stow
        else
            echo "please install the stow command
    https://www.gnu.org/software/stow" >&2
            exit 1
        fi
    fi
    if [ ! -d "$_STATE_PATH" ]; then
        mkdir -p "$_STATE_PATH"
    fi
    if (which prompt 2>&1 >/dev/null) && (which response 2>&1 >/dev/null) && [ ! -d "$DOTFILES_PATH" ]; then
        mkdir -p $_TMP_PATH
        true >$_TMP_PATH/cody.templates
        cat <<EOF >$_TMP_PATH/cody.templates
Template: dotstow/git_repo
Type: string
Description: git repo
 select the git repository that contains your dotfiles
Default: git@gitlab.com:$USER/dotfiles

EOF
        prompt "$_TMP_PATH/cody.templates"
        RESPONSE=$(response $_TMP_PATH/cody.templates)
        GIT_REPO=$(echo "$RESPONSE" | grep '^dotstow/git_repo:' | sed 's|^dotstow/git_repo:||g' | sed 's|,| |g')
        rm -rf $_TMP_PATH
        _init "$GIT_REPO"
    fi
}

_init() {
    _REPO=$1
    if [ "$_REPO" = "" ]; then
        echo "no repo specified" >&2
        exit 1
    fi
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
    _RM_FILES=$(echo $(for f in $(cd $_PACKAGE_DIR/$_PACKAGE && (find . -type f | sed "s|^./|$HOME/|g")); do
        if [ -f $f ]; then echo $f; fi
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
    ( (ls $DOTFILES_PATH/global 2>/dev/null || true) &&
        (ls $DOTFILES_PATH/$FLAVOR 2>/dev/null || true) &&
        (ls $DOTFILES_PATH/$PLATFORM 2>/dev/null || true)) | sort | uniq
}

_stowed() {
    (ls $_STOWED_PATH 2>/dev/null || true) | sort | uniq
}

_sync() {
    if [ ! -d "$DOTFILES_PATH" ]; then
        echo "dotfiles not initialized" >&2
        exit 1
    fi
    cd $DOTFILES_PATH
    echo '$ git add -A'
    git add -A
    echo '$ git commit -m "Updated '"$(git status | grep 'modified: ' | sed 's|^.*modified:\s*||g' | head -n1)"'"'
    git commit -m "Updated $(git status | grep 'modified: ' | sed 's|^.*modified:\s*||g' | head -n1)"
    echo '$ git pull'
    git pull
    echo '$ git push'
    (echo y) | git push
}

_wizard() {
    STOWED=$(dotstow stowed)
    NOT_STOWED=$( (dotstow stowed && dotstow available) | sort | uniq -u)
    if [ "$STOWED" != "" ]; then
        PACKAGES_UNSTOW=$(kwyzod enum -m "select the packages you wish to unstow" $STOWED)
        if [ "$(kwyzod boolean "UNSTOW PACKAGES\n\n$PACKAGES_UNSTOW")" != "1" ]; then
            exit 1
        fi

    fi
    if [ "$NOT_STOWED" != "" ]; then
        PACKAGES_STOW=$(kwyzod enum -m "select the packages you wish to stow" $NOT_STOWED)
        if [ "$(kwyzod boolean "STOW PACKAGES\n\n$PACKAGES_STOW")" != "1" ]; then
            exit 1
        fi
    fi
    for t in $PACKAGES_UNSTOW; do
        echo '$' dotstow unstow $t
        dotstow unstow $t
    done
    for l in $PACKAGES_STOW; do
        echo '$' dotstow stow $l
        dotstow stow $l
    done
}

_path() {
    echo "$DOTFILES_PATH"
}

_reset() {
    cd "$DOTFILES_PATH"
    git add -A
    git reset --hard
}

_status() {
    cd "$DOTFILES_PATH"
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
    elif (! which prompt 2>&1 >/dev/null) || (! which response 2>&1 >/dev/null) || [ -d "$DOTFILES_PATH" ]; then
        echo "no repo specified" 1>&2
        exit 1
    fi
    ;;
s | stow)
    shift
    if test $# -gt 0; then
        export _COMMAND=stow
    else
        echo "no package specified" 1>&2
        exit 1
    fi
    ;;
u | unstow)
    shift
    if test $# -gt 0; then
        export _COMMAND=unstow
    else
        echo "no package specified" 1>&2
        exit 1
    fi
    ;;
w | wizard)
    shift
    export _COMMAND=wizard
    ;;
a | available)
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
path)
    shift
    export _COMMAND=path
    ;;
reset)
    shift
    export _COMMAND=reset
    ;;
status)
    shift
    export _COMMAND=status
    ;;
*)
    echo "invalid command $1" 1>&2
    exit 1
    ;;
esac

kwyzod() {
    while [ $# -gt 0 ]; do
        case "$1" in
        --dialogs)
            KWYZOD_DIALOGS="$2"
            shift 2
            ;;
        --default | -d)
            KWYZOD_DEFAULT="$2"
            shift 2
            ;;
        --multiple | -m)
            _ENUM_MULTIPLE="1"
            shift
            ;;
        *)
            break
            ;;
        esac
    done
    _TYPE="$1"
    shift
    while [ $# -gt 0 ]; do
        case "$1" in
        --default | -d)
            KWYZOD_DEFAULT="$2"
            shift 2
            ;;
        --multiple | -m)
            _ENUM_MULTIPLE="1"
            shift
            ;;
        *)
            break
            ;;
        esac
    done
    case "$_TYPE" in
    dialogs)
        _kwyzod_dialogs "$@"
        ;;
    boolean)
        _kwyzod_boolean "$KWYZOD_DEFAULT" "$@"
        ;;
    string)
        _kwyzod_string "$KWYZOD_DEFAULT" "$@"
        ;;
    integer)
        _kwyzod_integer "$KWYZOD_DEFAULT" "$@"
        ;;
    enum)
        if [ -z "$_ENUM_MULTIPLE" ]; then
            _kwyzod_select "$KWYZOD_DEFAULT" "$@"
        else
            _kwyzod_multiselect "$KWYZOD_DEFAULT" "$@"
        fi
        ;;
    *)
        _kwyzod_help
        ;;
    esac
}

_kwyzod_help() {
    cat <<EOF
Usage: kwyzod <OPTIONS> [COMMAND] <TYPE_OPTIONS> <PROMPT>

[COMMAND]:
    dialogs              list installed dialogs
    boolean              prompt for a boolean value
    string               prompt for a string value
    integer              prompt for an integer value
    enum [...options]    prompt for an enum value

<OPTIONS>:
    --default, -d     set the default value
    --dialogs         comma separated list of ordered dialogs to use (eg: "zenity,dialog")
    --help, -h        display this help
    --multiple, -m    allow multiple selections (only for enum)
    --version, -v     display version

<TYPE_OPTIONS>:
    --default, -d     set the default value
    --multiple, -m    allow multiple selections (only for enum)

<PROMPT>: prompt displayed in the dialog box
EOF
}

_error() {
    echo "$@" >&2
}

_kwyzod_detect_dialogs() {
    _DIALOGS=""
    if [ -z "$KWYZOD_DIALOGS" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            KWYZOD_DIALOGS="osascript zenity yad kdialog"
        elif [ "$(uname)" = "Linux" ]; then
            if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
                KWYZOD_DIALOGS="kdialog zenity yad"
            else
                KWYZOD_DIALOGS="zenity yad kdialog"
            fi
        fi
        KWYZOD_DIALOGS="$KWYZOD_DIALOGS dialog whiptail"
    else
        KWYZOD_DIALOGS="$(echo "$KWYZOD_DIALOGS" | tr ',' ' ')"
    fi
    for _DIALOG in $KWYZOD_DIALOGS; do
        if command -v "$_DIALOG" >/dev/null 2>&1; then
            _DIALOGS="$_DIALOGS $_DIALOG"
        fi
    done
    echo "$_DIALOGS"
}

_kwyzod_get_dialog() {
    _SUPPORTED_DIALOGS="$@"
    _INSTALLED_DIALOGS="$(_kwyzod_detect_dialogs)"
    _DIALOG=""
    for d in $_INSTALLED_DIALOGS; do
        if echo " $_SUPPORTED_DIALOGS " | grep -q " $d "; then
            _DIALOG="$d"
            break
        fi
    done
    echo "$_DIALOG"
}

_kwyzod_dialogs() {
    _kwyzod_detect_dialogs | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr ' ' '\n'
}

_kwyzod_boolean() {
    _DEFAULT="$1"
    _PROMPT="$2"
    _RESULT=""
    _DIALOG=$(_kwyzod_get_dialog "osascript" "zenity" "kdialog" "yad" "dialog" "whiptail")
    if [ -z "$_DIALOG" ]; then
        printf "%s [Y|n]: " "$_PROMPT"
        read -r _ANSWER
        case "$_ANSWER" in
        [Nn]*)
            _RESULT="0"
            ;;
        *)
            _RESULT="1"
            ;;
        esac
    else
        case "$_DIALOG" in
        osascript)
            _OSASCRIPT_OUTPUT="$(osascript -e 'tell application "System Events" to display dialog '"\"$_PROMPT\""' buttons {"Yes", "No"} default button "Yes" giving up after 86400' -e 'button returned of result')"
            _RESULT="$([ "$_OSASCRIPT_OUTPUT" = "Yes" ] && echo "1" || echo "0")"
            ;;
        zenity)
            _RESULT="$(zenity --question --text "$_PROMPT" && echo "1" || echo "0")"
            ;;
        kdialog)
            _RESULT="$(kdialog --yesno "$_PROMPT" && echo "1" || echo "0")"
            ;;
        yad)
            _RESULT="$(yad --question --text "$_PROMPT" && echo "1" || echo "0")"
            ;;
        dialog)
            dialog --yesno "$_PROMPT" 10 40 2>&1 >/dev/tty && _RESULT="1" || _RESULT="0"
            ;;
        whiptail)
            whiptail --yesno "$_PROMPT" 10 40 --yes-button "Yes" --no-button "No" && _RESULT="1" || _RESULT="0"
            ;;
        esac
    fi
    echo "$_RESULT"
}

_kwyzod_string() {
    _DEFAULT="$1"
    _PROMPT="$2"
    _RESULT=""
    _DIALOG=$(_kwyzod_get_dialog "osascript" "zenity" "kdialog" "yad" "dialog" "whiptail")
    if [ -z "$_DIALOG" ]; then
        if [ -z "$_DEFAULT" ]; then
            printf "%s: " "$_PROMPT"
        else
            printf "%s (%s): " "$_PROMPT" "$_DEFAULT"
        fi
        read -r _RESULT
        if [ -z "$_RESULT" ]; then
            _RESULT="$_DEFAULT"
        fi
    else
        case "$_DIALOG" in
        osascript)
            _RESULT=$(
                osascript <<EOF
            text returned of (display dialog "$_PROMPT" default answer "$_DEFAULT" buttons {"OK"} default button 1)
EOF
            )
            ;;
        zenity)
            _RESULT="$(zenity --entry --text "$_PROMPT" --entry-text="$_DEFAULT")"
            ;;
        kdialog)
            _RESULT="$(kdialog --inputbox "$_PROMPT" "$_DEFAULT")"
            ;;
        yad)
            _RESULT="$(yad --entry --text="$_PROMPT" --entry-text="$_DEFAULT")"
            ;;
        dialog)
            _RESULT="$(dialog --inputbox "$_PROMPT" 10 40 "$_DEFAULT" 3>&1 1>&2 2>&3)"
            ;;
        whiptail)
            _RESULT="$(whiptail --inputbox "$_PROMPT" 10 40 "$_DEFAULT" 3>&1 1>&2 2>&3)"
            ;;
        esac
    fi
    echo "$_RESULT"
}

_kwyzod_integer() {
    _DEFAULT="$1"
    _PROMPT="$2"
    _RESULT=""
    _DIALOG="$(_kwyzod_get_dialog "osascript" "zenity" "kdialog" "yad" "dialog" "whiptail")"
    if [ -z "$_DIALOG" ]; then
        if [ -z "$_DEFAULT" ]; then
            printf "%s: " "$_PROMPT"
        else
            printf "%s (%s): " "$_PROMPT" "$_DEFAULT"
        fi
        read -r _RESULT
        if [ -z "$_RESULT" ]; then
            _RESULT="$_DEFAULT"
        fi
    else
        case "$_DIALOG" in
        osascript)
            _RESULT=$(
                osascript <<EOF
                text returned of (display dialog "$_PROMPT" default answer "$_DEFAULT" buttons {"OK"} default button 1)
EOF
            )
            ;;
        zenity)
            _RESULT="$(zenity --entry --text "$_PROMPT" --entry-text="$_DEFAULT")"
            ;;
        kdialog)
            _RESULT="$(kdialog --inputbox "$_PROMPT" "$_DEFAULT")"
            ;;
        yad)
            _RESULT="$(yad --form --text="$_PROMPT" --field="":NUM "$_DEFAULT" | sed 's/|[[:space:]]*$//'))"
            ;;
        dialog)
            _RESULT="$(dialog --inputbox "$_PROMPT" 10 40 "$_DEFAULT" 3>&1 1>&2 2>&3)"
            ;;
        whiptail)
            _RESULT="$(whiptail --inputbox "$_PROMPT" 10 40 "$_DEFAULT" 3>&1 1>&2 2>&3)"
            ;;
        esac
    fi
    _RESULT="$(echo "$_RESULT" | cut -d'.' -f1)"
    _RESULT="$(echo "$_RESULT" | tr -d -c 0-9)"
    if [ -z "$_RESULT" ]; then
        _RESULT="0"
    fi
    echo "$_RESULT"
}

_kwyzod_select() {
    _DEFAULT="$1"
    _PROMPT="$2"
    shift 2
    set -- "$@"
    _RESULT=""
    _DIALOG=$(_kwyzod_get_dialog "osascript" "zenity" "kdialog" "yad" "dialog" "whiptail")
    if [ -z "$_DIALOG" ]; then
        _OPTIONS=""
        for _OPTION in "$@"; do
            if [ "$_OPTION" != "$_DEFAULT" ]; then
                _OPTIONS="$_OPTIONS \"$_OPTION\""
            fi
        done
        eval set -- $_OPTIONS
        if [ -n "$_DEFAULT" ]; then
            set -- "$_DEFAULT" "$@"
        fi
        i=1
        for _OPTION; do
            if [ "$_OPTION" == "$_DEFAULT" ]; then
                printf "*%s) %s\n" "$i" "$_OPTION"
            else
                if [ -z "$_DEFAULT" ]; then
                    printf "%s) %s\n" "$i" "$_OPTION"
                else
                    printf " %s) %s\n" "$i" "$_OPTION"
                fi
            fi
            i="$((i + 1))"
        done
        printf "%s: " "$_PROMPT"
        read -r _RESULT
        if [ -z "$_RESULT" ]; then
            _RESULT="$_DEFAULT"
        else
            _RESULT="$(eval "echo \$$((_RESULT))")"
        fi
    else
        case "$_DIALOG" in
        osascript)
            if [ -n "$_DEFAULT" ]; then
                _OPTIONS="\"$_DEFAULT\""
            fi
            for _OPTION; do
                if [ "$_OPTION" != "$_DEFAULT" ]; then
                    _OPTIONS="$_OPTIONS, \"$_OPTION\""
                fi
            done
            _RESULT="$(osascript -e "choose from list {$_OPTIONS} with prompt \"$_PROMPT\"")"
            ;;
        zenity)
            if [ -n "$_DEFAULT" ]; then
                _OPTIONS="\"$_DEFAULT\""
            fi
            for _OPTION in "$@"; do
                if [ "$_OPTION" != "$_DEFAULT" ]; then
                    _OPTIONS="$_OPTIONS \"$_OPTION\""
                fi
            done
            _RESULT="$(eval zenity --list --text=\"$_PROMPT\" --column=\"Options\" $_OPTIONS)"
            ;;
        kdialog)
            _RESULT="$(kdialog --radiolist "$_PROMPT" "$_DEFAULT" "$@")"
            ;;
        yad)
            _OPTIONS="$_DEFAULT"
            for _OPTION; do
                if [ "$_OPTION" != "$_DEFAULT" ]; then
                    _OPTIONS="$_OPTIONS\!$_OPTION"
                fi
            done
            _RESULT="$(yad --form --text="$_PROMPT" --field="":CB "$_OPTIONS" | sed 's/|[[:space:]]*$//')"
            ;;
        dialog)
            if [ -n "$_DEFAULT" ]; then
                _OPTIONS="\"$_DEFAULT\" \"1\" \"on\""
                _COUNT=2
            else
                _COUNT=1
            fi
            i=1
            while [ $i -le $# ]; do
                _OPTION="$(eval "echo \$$i")"
                if [ "$_OPTION" != "$_DEFAULT" ]; then
                    _OPTIONS="$_OPTIONS \"$_OPTION\" \"$_COUNT\" \"off\""
                    _COUNT="$((_COUNT + 1))"
                fi
                i="$((i + 1))"
            done
            _RESULT="$(eval dialog --radiolist \"$_PROMPT\" 15 40 10 $_OPTIONS 3>&1 1>&2 2>&3)"
            ;;
        whiptail)
            _RESULT="$(whiptail --menu "$_PROMPT" 15 40 10 "$_DEFAULT" "$@" 3>&1 1>&2 2>&3)"
            ;;
        esac
    fi
    echo "$_RESULT"
}

_kwyzod_multiselect() {
    _DEFAULT="$1"
    _PROMPT="$2"
    shift 2
    set -- "$@"
    _RESULT=""
    _DIALOG=$(_kwyzod_get_dialog "osascript" "zenity" "kdialog" "yad" "dialog" "whiptail")
    if [ -z "$_DIALOG" ]; then
        i=1
        for _OPTION; do
            printf "%s) %s\n" "$i" "$_OPTION"
            i="$((i + 1))"
        done
        printf "%s: " "$_PROMPT"
        read -r _RESULTS
        _RESULT=""
        for _INDEX in $_RESULTS; do
            _RESULT+="$(eval "echo \$$_INDEX")\n"
        done
        _RESULT="${_RESULT%\\n}"
    else
        case "$_DIALOG" in
        osascript)
            _OPTIONS="$(printf ", \"%s\"" "$@")"
            _OPTIONS="$(echo "$_OPTIONS" | cut -c 3-)"
            _RESULT="$(osascript -e "choose from list {$_OPTIONS} with prompt \"$_PROMPT\" with multiple selections allowed")"
            _RESULT="$(echo "$_RESULT" | sed 's/, /\n/g')"
            ;;
        zenity)
            _RESULT="$(zenity --list --multiple --text="$_PROMPT" --column="Options" "$@" | sed 's/|/\n/g')"
            ;;
        kdialog)
            _RESULT="$(kdialog --checklist "$_PROMPT" "$@")"
            ;;
        yad)
            _OPTIONS=""
            for _OPTION; do
                _OPTIONS="$_OPTIONS --field=\"$_OPTION\":CHK"
            done
            _RESULT="$(eval yad --form --text=\"$_PROMPT\" $_OPTIONS)"
            _RESULT="$(echo "$_RESULT" | tr '|' '\n')"
            _INDEX=1
            for _VALUE in $_RESULT; do
                if [ "$_VALUE" = "TRUE" ]; then
                    _RESULT+="$(eval "echo \$$_INDEX")|"
                fi
                _INDEX="$((_INDEX + 1))"
            done
            _RESULT="$(echo "${_RESULT%?}" | sed 's/|/\n/g')"
            ;;
        dialog)
            _OPTIONS=""
            i=1
            while [ $i -le $# ]; do
                _OPTIONS="$_OPTIONS \"$(eval "echo \$$i")\" \"$i\" \"off\""
                i="$((i + 1))"
            done
            _RESULT="$(eval dialog --checklist \"$_PROMPT\" 15 40 10 $_OPTIONS 3>&1 1>&2 2>&3)"
            _RESULT="$(echo "$_RESULT" | awk 'BEGIN{RS="\"";ORS="\n"}{if(NR%2==0){print $0}else{gsub(/ /,"\n");print $0}}' | awk 'NF')"
            ;;
        whiptail)
            _RESULT="$(whiptail --checklist "$_PROMPT" 15 40 10 "$@" 3>&1 1>&2 2>&3)"
            ;;
        esac
    fi
    echo "$_RESULT"
}

main $@
