# dotstow

> manage dotfiles with git and stow

`dotstow` is a tool to manage your dotfiles using Git and Stow.
It allows you to keep your dotfiles in a version control system
and easily sync them across multiple computers.

## Install

To install dotstow, run the following command:

```sh
$(curl --version >/dev/null 2>/dev/null && echo curl -L || echo wget -O-) https://gitlab.com/risserlabs/community/dotstow/-/raw/main/install.sh 2>/dev/null | sh
```

## Usage

1. Initialize dotstow

   To start using dotstow, you need to initialize it with your Git repository. Run the following command:

   ```sh
   dotstow init <REPO>
   ```

   Replace <REPO> with the URL of your Git repository. This will create a .dotfiles folder in your home directory and clone your Git repository into it.

2. Stow a package

   Once you have initialized dotstow, you can stow a package using the following command:

   ```sh
   dotstow stow <PACKAGE>
   ```

   Replace <PACKAGE> with the name of the package you want to stow. This will create symbolic links in your home directory to the corresponding files in the package folder.

3. Sync dotfiles

   To sync your dotfiles with the Git repository, use the following command:

   ```sh
   dotstow sync
   ```

   This will commit and push any changes in your dotfiles to the Git repository.

## Organization

dotstow searches for packages in one of three folder: global, <PLATFORM>, and <FLAVOR>. These folders are
determined based on the operating system and architecture of your computer.

Here are some examples of how dotstow determines the <PLATFORM> and <FLAVOR> folders
based on the current operating system:

On Linux, the <PLATFORM> folder is called `linux` and the <FLAVOR> folder is the Linux distribution name,
for example `debian`, `suse`, `alpine` or `rhel`.
On macOS, dotstow sets <PLATFORM> to `darwin`. The <FLAVOR> folder is not supported on macOS.

The folders are searched in the following order:

- <FLAVOR>
- <PLATFORM>
- global

For example, if you're on a Linux machine with the <FLAVOR> set to `debian`, and you run the command `dotstow stow zsh`,
dotstow will look for the zsh package in the following folders, in order:

- `debian/zsh`
- `linux/zsh`
- `global/zsh`

If dotstow finds the zsh package in the `debian/zsh` folder, it will create symbolic links to the
files in that folder in your home directory.

## Example

You can use my dotfiles as an example, reference or even a starting point for your dotfiles.

[gitlab.com/clayrisser/dotfiles](https://gitlab.com/clayrisser/dotfiles.git)

## Other Commands

`dotstow` provides several other commands to manage your dotfiles. Here is a list of some of them:

- `dotstow unstow <PACKAGE>`: Remove symbolic links to a package.
- `dotstow wizard`: Interactive command to add and remove packages.
- `dotstow available`: List available packages in your Git repository.
- `dotstow stowed`: List packages that have been stowed.
- `dotstow status`: Show the Git status of your dotfiles.
- `dotstow reset`: Reset your dotfiles to the last commit.
- `dotstow path`: Print the path of your dotfiles folder.

```
dotstow - manage dotfiles with git and stow

dotstow [options] command <PACKAGE>

options:
    -h, --help            show brief help

commands:
    init <REPO>            initialize dotstow
    s, stow <PACKAGE>      stow a package
    u, unstow <PACKAGE>    unstow a package
    w, wizard              dotfiles wizard
    a, available           available packages
    stowed                 stowed packages
    sync                   sync dotfiles
    status                 dotfiles git status
    reset                  reset dotfiles
    path                   get dotfiles path
```

## Dependencies

- [Git](https://git-scm.com)
- [GNU Stow](https://www.gnu.org/software/stow)
