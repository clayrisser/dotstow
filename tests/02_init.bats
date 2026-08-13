#!/usr/bin/env bats
load helper.sh

setup() {
    setup_sandbox
}

@test "init clones the dotfiles repo and links ~/.dotfiles" {
    ORIGIN=$(make_dotfiles_repo)
    run dotstow init "$ORIGIN"
    [ "$status" -eq 0 ]
    [ -d "$DOTFILES/.git" ]
    [ -L "$HOME/.dotfiles" ]
    [ "$(cd "$HOME/.dotfiles" && pwd -P)" = "$(cd "$DOTFILES" && pwd -P)" ]
}

@test "init a second time fails" {
    ORIGIN=$(make_dotfiles_repo)
    dotstow init "$ORIGIN"
    run dotstow init "$ORIGIN"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "already initialized"
}

@test "init with an unreachable repo fails and leaves no ~/.dotfiles link" {
    run dotstow init "$BATS_TEST_TMPDIR/does-not-exist.git"
    [ "$status" -ne 0 ]
    [ ! -e "$HOME/.dotfiles" ]
    [ ! -L "$HOME/.dotfiles" ]
}

@test "path prints the dotfiles path" {
    ORIGIN=$(make_dotfiles_repo)
    dotstow init "$ORIGIN"
    run dotstow path
    [ "$status" -eq 0 ]
    [ "$output" = "$DOTFILES" ]
}

@test "DOTFILES_PATH env var overrides the default location" {
    ORIGIN=$(make_dotfiles_repo)
    export DOTFILES_PATH="$BATS_TEST_TMPDIR/custom-dotfiles"
    dotstow init "$ORIGIN"
    [ -d "$DOTFILES_PATH/.git" ]
    run dotstow path
    [ "$output" = "$DOTFILES_PATH" ]
}
