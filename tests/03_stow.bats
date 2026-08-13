#!/usr/bin/env bats
load helper.sh

setup() {
    setup_sandbox
    ORIGIN=$(make_dotfiles_repo)
    dotstow init "$ORIGIN" >/dev/null
}

@test "available lists packages from all groups" {
    run dotstow available
    [ "$status" -eq 0 ]
    echo "$output" | grep -qx zsh
    echo "$output" | grep -qx nvim
    echo "$output" | grep -qx foo
}

@test "stow creates symlinks into the dotfiles repo" {
    run dotstow stow zsh
    [ "$status" -eq 0 ]
    [ -L "$HOME/.zshrc" ]
    grep -q DOTSTOW_TEST "$HOME/.zshrc"
}

@test "stow prefers the platform group over global" {
    run dotstow stow foo
    [ "$status" -eq 0 ]
    grep -q 'from platform' "$HOME/.foorc"
}

@test "stowed lists stowed packages" {
    dotstow stow zsh
    run dotstow stowed
    [ "$status" -eq 0 ]
    echo "$output" | grep -qx zsh
}

@test "stow replaces a conflicting regular file" {
    echo 'old content' >"$HOME/.zshrc"
    run dotstow stow zsh
    [ "$status" -eq 0 ]
    [ -L "$HOME/.zshrc" ]
    grep -q DOTSTOW_TEST "$HOME/.zshrc"
}

@test "stow replaces a conflicting foreign symlink" {
    ln -s "$BATS_TEST_TMPDIR/nowhere" "$HOME/.zshrc"
    run dotstow stow zsh
    [ "$status" -eq 0 ]
    [ -L "$HOME/.zshrc" ]
    grep -q DOTSTOW_TEST "$HOME/.zshrc"
}

@test "restowing a folded package does not destroy repo files" {
    dotstow stow nvim
    [ -L "$HOME/.config" ]
    run dotstow stow nvim
    [ "$status" -eq 0 ]
    [ -f "$DOTFILES/global/nvim/.config/nvim/init.vim" ]
    grep -q 'set number' "$HOME/.config/nvim/init.vim"
}

@test "stow errors on an unknown package" {
    run dotstow stow nope
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "not found"
}

@test "unstow removes symlinks and the stowed marker" {
    dotstow stow zsh
    dotstow unstow zsh
    [ ! -e "$HOME/.zshrc" ]
    [ ! -L "$HOME/.zshrc" ]
    run dotstow stowed
    [ "$output" = "" ]
}

@test "unstow errors on an unknown package" {
    run dotstow unstow nope
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "not found"
}
