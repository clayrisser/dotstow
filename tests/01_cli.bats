#!/usr/bin/env bats
load helper.sh

setup() {
    setup_sandbox
}

@test "prints help when run without arguments" {
    run dotstow
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "manage dotfiles with git and stow"
}

@test "prints help for -h and --help" {
    run dotstow -h
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "manage dotfiles with git and stow"
    run dotstow --help
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "manage dotfiles with git and stow"
}

@test "rejects an invalid option" {
    run dotstow --bogus
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "invalid option"
}

@test "rejects an invalid command" {
    run dotstow bogus
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "invalid command"
}

@test "stow without a package errors" {
    run dotstow stow
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "no package specified"
}

@test "unstow without a package errors" {
    run dotstow unstow
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "no package specified"
}
