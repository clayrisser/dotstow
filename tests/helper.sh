# Shared helpers for the dotstow bats suite. POSIX sh.
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${BATS_TEST_DIRNAME:-$(dirname -- "$0")}/.." && pwd)}"

dotstow() {
    sh "$PROJECT_ROOT/dotstow.sh" "$@"
}

# Point HOME and XDG state at per-test scratch space so nothing touches the
# real user environment.
setup_sandbox() {
    HOME="$BATS_TEST_TMPDIR/home"
    XDG_STATE_HOME="$HOME/.local/state"
    DOTFILES="$XDG_STATE_HOME/dotstow/dotfiles"
    GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"
    GIT_CONFIG_SYSTEM=/dev/null
    export HOME XDG_STATE_HOME GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM
    unset DOTFILES_PATH
    mkdir -p "$HOME"
    printf '[user]\n\tname = dotstow test\n\temail = test@example.com\n[init]\n\tdefaultBranch = main\n' \
        >"$GIT_CONFIG_GLOBAL"
}

# Create a bare origin repo seeded with fixture packages; prints its path.
# Packages: global/zsh, global/nvim (nested dirs, exercises stow folding),
# and a <platform>/foo + global/foo pair for group-priority tests.
make_dotfiles_repo() {
    _ORIGIN="$BATS_TEST_TMPDIR/origin.git"
    _SEED="$BATS_TEST_TMPDIR/seed"
    _PLATFORM=$(uname | tr '[:upper:]' '[:lower:]')
    git init -q --bare "$_ORIGIN"
    git init -q "$_SEED"
    mkdir -p "$_SEED/global/zsh" "$_SEED/global/nvim/.config/nvim" \
        "$_SEED/global/foo" "$_SEED/$_PLATFORM/foo"
    echo 'export DOTSTOW_TEST=1' >"$_SEED/global/zsh/.zshrc"
    echo 'set number' >"$_SEED/global/nvim/.config/nvim/init.vim"
    echo 'from global' >"$_SEED/global/foo/.foorc"
    echo 'from platform' >"$_SEED/$_PLATFORM/foo/.foorc"
    git -C "$_SEED" add -A
    git -C "$_SEED" commit -qm 'test fixture'
    git -C "$_SEED" push -q "$_ORIGIN" main
    printf '%s\n' "$_ORIGIN"
}
