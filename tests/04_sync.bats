#!/usr/bin/env bats
load helper.sh

setup() {
    setup_sandbox
    ORIGIN=$(make_dotfiles_repo)
    dotstow init "$ORIGIN" >/dev/null
}

@test "status reports a clean tree" {
    run dotstow status
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "working tree clean"
}

@test "sync commits local changes and pushes them to origin" {
    echo 'export EDITED=1' >>"$DOTFILES/global/zsh/.zshrc"
    run dotstow sync
    [ "$status" -eq 0 ]
    [ "$(git -C "$DOTFILES" status --porcelain)" = "" ]
    git -C "$ORIGIN" log -1 --format=%s | grep -q "Updated"
    git -C "$ORIGIN" show HEAD:global/zsh/.zshrc | grep -q EDITED
}

@test "sync with no changes still succeeds" {
    run dotstow sync
    [ "$status" -eq 0 ]
}

@test "reset discards uncommitted changes" {
    echo 'export EDITED=1' >>"$DOTFILES/global/zsh/.zshrc"
    run dotstow reset
    [ "$status" -eq 0 ]
    ! grep -q EDITED "$DOTFILES/global/zsh/.zshrc"
}
