# dotstow

> manage dotfiles with stow

## Install

```sh
$(curl --version >/dev/null 2>/dev/null && echo curl -L || echo wget -O-) https://gitlab.com/risserlabs/community/dotstow/-/raw/main/install.sh 2>/dev/null | sh
```

## Usage

1. Initialize dotstow

    ```sh
    dotstow init git@gitlab.com:clayrisser/dotfiles.git
    ```

2. Stow a package

    ```sh
    dotstow stow zsh # symlinks zsh package
    ```

3. Sync dotfiles

    ```sh
    dotstow sync
    ```

```
dotstow - manage dotfiles with stow and make

dotstow [options] command <PACKAGE>

options:
    -h, --help            show brief help

commands:
    init <REPO>            initialize dotstow
    s, stow <PACKAGE>      stow a package
    u, unstow <PACKAGE>    unstow a package
    a, available           available packages
    stowed                 stowed packages
    sync                   sync dotfiles
```
