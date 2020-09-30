# dotstow

[![GitHub stars](https://img.shields.io/github/stars/codejamninja/dotstow.svg?style=social&label=Stars)](https://github.com/codejamninja/dotstow)

> manage dotfiles with stow

Please ★ this repo if you found it useful ★ ★ ★

Windows support has not been tested.

## Built by Silicon Hills LLC

[![index](https://user-images.githubusercontent.com/6234038/71054254-f284ad80-2116-11ea-9013-d68306726854.jpeg)](https://nuevesolutions.com)

Silicon Hills offers premium Node and React develpoment and support services. Get in touch at [nuevesolutions.com](https://nuevesolutions.com).

## Related Projects

You can see some dotfiles repos (which are using dotstow) at the link below.

- [codejamninja/dotfiles](https://github.com/codejamninja/dotfiles)
- [sreerajkksd/dotfiles](https://github.com/sreerajkksd/dotfiles)

You can read more about dotstow at the blog post below.

https://dev.to/codejamninja/dotstow-the-smart-way-to-manage-your-dotfiles-25ik

## Features

- Group dotfiles into units (stow packages)
- Automatically symlink (stow) files
- Backup dotfiles with git
- Keep track of simultaneous dotfile configurations for multiple environments
- Supports shell autocompletion
- Supports bootstraping using a config

## Installation

```sh
npm install -g dotstow
```

## Dependencies

- [NodeJS](https://nodejs.org) ( > nodejs 12)
- [GNU Stow](https://www.gnu.org/software/stow)

## Usage

Note that unlike many dotfile syncing tools, this is powered by
[GNU Stow](https://www.gnu.org/software/stow). This means your dotfiles must be stored inside
stow packages (subfolders) instead of the root of your repo. This prevents cluttering your home
directory with unwanted files, like your `README.md`. It also enables you to only install dotfiles
you want on that computer.

The idea behind dotstow is twofold:

1. You don't need to maintain a shell script that symlinks all of your dotfiles to the correct
   places in your \$HOME directory upon a new dotfile install
2. Individual directories in your .dotfiles become packages that can be installed independently
   using `dotstow stow [package]`

For example:

When setting up your dotfiles on a new computer

1. Run `dotstow bootstrap --remote <GITHUB_REPO_LINK>`, and watch as it's cloned into `~/.dotfiles` and would run the scripts configured in bootstrap.yml.
2. Run`dotstow stow zsh emacs vim ...` etc for each of the stow packages you'd like to install (aka symlink to \$HOME).
3. To pull **the latest changes** from the remote repository, run `dotstow pull`.
4. When you **update a file** in a package, you only need to `dotstow sync` to update your linked github repo
   with the changes. This takes care of committing/pushing the changes to the repository.

   Note: If you **add new files** to your stow package, you will need to restow the package.
   For example, when adding `.zshrc` to `.dotfiles/globals/zsh/`, you will need to `dotstow stow zsh` to restow the package
   and then `dotstow sync` to update your linked github repo with the changes.

5. bootstrap.yml config can be placed on any environment directory (including global) and should contain the message and cmd keys for any item. See [sample config here](#Sample-bootstrap.yml-config)

```
USAGE
  $ dotstow [COMMAND]

COMMANDS
  autocomplete  display autocomplete installation instructions
  bootstrap     bootstrap dotfiles
  help          display help for dotstow
  pull          pull dotfiles
  stow          stow dotfiles
  sync          sync dotfiles
```

### Environments

Environments is how dotstow lets you have multiple configurations for a single package. This is extremely useful
if you have multiple operating systems that require slighty different configurations while still keeping
all your dotfiles togather. For example, maybe your `zsh` would be configured differently on `osx` than on `linux`.

Dotstow tries to guess your environment. You can always force an environment by using the `--environment` flag,
for example `--environment=ubuntu`.

Dotstow first tries to guess the environment by looking for a package in the folder with the name or your hostname.
I name my computers after famous dragons, so if my hostname was `drogon` it would look in `~/.dotfiles/drogon` for
the package.

If the package is not found, dotstow will proceed to look for a package in a folder with the type of the operating
you are using. For example, if you were running `ubuntu`, dotstow would look in `~/.dotfiles/ubuntu`, `~/.dotfiles/debian`,
`~/.dotfiles/linux` and `~/.dotfiles/unix` for the package.

Dotstow can guess multiple operating systems.

```
    aix
    amigaos
    android
    beos
    bsd
    centos
    darwin
    debian
    fedora
    freebsd
    ios
    linux
    mac
    nintendo
    openbsd
    osx
    redhat
    rhel
    slackware
    starBlade
    sunos
    ubuntu
    unix
    value
    win
    win32
    win64
    windows
```

### Bootstrap

bootstrap.yml is meant to configure things that should have done before actually stowing the packages. Cloning certain directories and keeping them at certain locations is an example of that sort. bootstrap also takes care of cloning the dotfiles directory and you can start stowing packages right after this.

```
bootstrap dotfiles

USAGE
  $ dotstow bootstrap

OPTIONS
  -d, --dotfiles=dotfiles
  -e, --environment=environment
  -r, --remote=remote
  --debug

EXAMPLE
  $ dotstow bootstrap --remote https://github.com/sreerajkksd/dotfiles.git
```

## Sample bootstrap.yml config

```yaml
- message: Setting up Vim Plug
  cmd: curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

- message: Setting up Tmux TPM
  cmd: git clone -q --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

- message: Setting up ohm-my-zsh
  cmd: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

- message: Installing VIM Plug
  cmd: vim +'PlugInstall --sync' +qa
```

### Stow

```
USAGE
  $ dotstow stow PACKAGES...

OPTIONS
  -d, --dotfiles=dotfiles
  -e, --environment=environment
  -f, --force
  -s, --sync
  --debug

EXAMPLE
  $ dotstow stow
```

### Sync

```
USAGE
  $ dotstow sync

OPTIONS
  -d, --debug

EXAMPLE
  $ dotstow sync
```

### Autocompletion

If you want to enable shell autocompletion, simply run the following command
and follow the instructions. Most standard shells are supported, such as
`bash` and `zsh`.

```
USAGE
  $ dotstow autocomplete [SHELL]

ARGUMENTS
  SHELL  shell type

OPTIONS
  -r, --refresh-cache  Refresh cache (ignores displaying instructions)

EXAMPLES
  $ dotstow autocomplete
  $ dotstow autocomplete bash
  $ dotstow autocomplete zsh
  $ dotstow autocomplete --refresh-cache
```

## Migration

### Python dotstow

If you were using the python version of dotstow, you should upgrade to
this version to get the benefits of multiple environments. If you switch
you will have to move your stash plugins into an environment folder (`global` is recommended).

You can do that by running the following commands.

```sh
mkdir ~/tmp_global
mv ~/.dotfiles/* ~/tmp_global
mv ~/tmp_global mkdir ~/.dotfiles/global
```

## Setting up dev instance

```sh

git clone https://github.com/codejamninja/dotstow.git
cd dotstow
npm install --also=dev

# To start the compiled dotstow code:
# Note: Ensure that you have yarn installed. (else install it using `npm install -g yarn`)
yarn
yarn start

# If you want test a command.
yarn start <command>
```

## FAQ

### Stowing zsh would cause conflicts

If you get an error similar to the one below, simply force stowing by passing
the `-f` or `--force` flag.

```
✖ WARNING! stowing zsh would cause conflicts:
  * existing target is not owned by stow: .zsh_aliases
  * existing target is not owned by stow: .zsh_envs
  * existing target is not owned by stow: .zsh_sources
  * existing target is not owned by stow: .zshrc
All operations aborted.
```

For example . . .

```sh
dotstow stow -f zsh
```

**Please understand this will overrite any existing file.**

## Support

Submit an [issue](https://github.com/codejamninja/dotstow/issues/new)

## Screenshots

[Contribute](https://github.com/codejamninja/dotstow/blob/master/CONTRIBUTING.md) a screenshot

## Contributing

Review the [guidelines for contributing](https://github.com/codejamninja/dotstow/blob/master/CONTRIBUTING.md)

## License

[MIT License](https://github.com/codejamninja/dotstow/blob/master/LICENSE)

[Jam Risser](https://codejam.ninja) © 2019

## Changelog

Review the [changelog](https://github.com/codejamninja/dotstow/blob/master/CHANGELOG.md)

## Credits

- [Jam Risser](https://codejam.ninja) - Author

## Support on Liberapay

A ridiculous amount of coffee ☕ ☕ ☕ was consumed in the process of building this project.

[Add some fuel](https://liberapay.com/codejamninja/donate) if you'd like to keep me going!

[![Liberapay receiving](https://img.shields.io/liberapay/receives/codejamninja.svg?style=flat-square)](https://liberapay.com/codejamninja/donate)
[![Liberapay patrons](https://img.shields.io/liberapay/patrons/codejamninja.svg?style=flat-square)](https://liberapay.com/codejamninja/donate)
