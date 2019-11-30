# dotstow (DEPRICATED)

[![GitHub stars](https://img.shields.io/github/stars/codejamninja/dotstow.svg?style=social&label=Stars)](https://github.com/codejamninja/dotstow)

> Manage dotfiles with stow

Please ★ this repo if you found it useful ★ ★ ★

# DEPRICATED

The pypi dotstow module is deprecated.

Please use the one found on npm.
https://npmjs.org/package/dotstow

You can install it by running the following command.

```
npm install -g dotstow
```

The new and improved dotstow module on npm
supports  the following features.

* Group dotfiles into units (stow packages)
* Automatically symlink (stow) files
* Backup dotfiles with git
* Keep track of simultaneous dotfile configurations for multiple environments
* Supports shell autocompletion


If you were using the python version of dotstow, you should upgrade to this
version to get the benefits of multiple environments. If you switch you will
have to move your stash plugins into an environment folder (global is recommended).

You can do that by running the following commands.

```
mkdir ~/tmp_global
mv ~/.dotfiles/* ~/tmp_global
mv ~/tmp_global mkdir ~/.dotfiles/global
```

## Features

* Group dotfiles into units (stow packages)
* Automatically symlink (stow) files
* Backup dotfiles with git

## Screenshots

![Screenshot 1](https://user-images.githubusercontent.com/6234038/41395410-37fe7bb8-6f73-11e8-97f2-c950da80dab3.jpg)


## Installation

```sh
pip3 install dotstow
```


## Dependencies

* [Python 3](https://www.python.org)
* [GNU Stow](https://www.gnu.org/software/stow)


## Usage

Note that unlike many dotfile syncing tools, this is powered by
[GNU Stow](https://www.gnu.org/software/stow). This means your dotfiles must be stored inside
stow packages (subfolders) instead of the root of your repo. This prevents cluttering your home
directory with unwanted files, like your `README.md`. It also enables you to only install dotfiles
you want on that computer.

The idea behind dotstow is twofold:
  1. You don't need to maintain a shell script that symlinks all of your dotfiles to the correct
  places in your $HOME directory upon a new dotfile install
  2. Individual directories in you .dotfiles become packages that can be installed independently
  using `dotstow [package]`

For example:

When setting up your dotfiles on a new computer
  1. Run `dotstow sync`, give it your dotfiles github repo link, and watch as it's cloned into `~/.dotfiles`.
  2. Run`dotstow zsh emacs vim ...` etc for each of the stow packages you'd like to install (aka symlink to $HOME).
  3. When you __update a file__ in a package, you only need to `dotstow sync` to update your linked github repo
  with the changes. If you __add new files__ to your stow package you will need to restow the package.
  For example, when adding `.zshrc` to `.dotfiles/zsh/`, you will need to `dotstow zsh` to restow the package
  and then `dotstow sync` to update your linked github repo with the changes.

### Setup

Create a remote dotfiles repo. You can create one at [GitHub](https://github.com/new).

Run the following command
```sh
dotstow sync
```

### Creating a stow package

```sh
mkdir ~/.dotfiles/my-stow-package
```

### Adding dotfiles to stow package

```sh
mv ~/.some-dotfile ~/.dotfiles/my-stow-package
```

### Symlink stow package

Note that this will fail if conflicting files exist in the home directory.

```sh
dotstow my-stow-package
```

### Syncing dotfiles

```sh
dotstow sync
```

### Example

The following example demonstrates syncing your `.zshrc` file with dotstow
```sh
mkdir ~/.dotstow/zsh       # creates a new stow package called 'zsh'
mv ~/.zshrc ~/.dotstow/zsh # adds dotfiles to the 'zsh' stow package
dotstow zsh                # symlinks the 'zsh' stow package
dotstow sync               # syncs your dotfiles
```


## Support

Submit an [issue](https://github.com/codejamninja/dotstow/issues/new)


## Contributing

Review the [guidelines for contributing](https://github.com/codejamninja/dotstow/blob/master/CONTRIBUTING.md)


## License

[MIT License](https://github.com/codejamninja/dotstow/blob/master/LICENSE)

[Jam Risser](https://codejam.ninja) © 2018


## Changelog

Review the [changelog](https://github.com/codejamninja/dotstow/blob/master/CHANGELOG.md)


## Credits

* [Jam Risser](https://codejam.ninja) - Author


## Support on Liberapay

A ridiculous amount of coffee ☕ ☕ ☕ was consumed in the process of building this project.

[Add some fuel](https://liberapay.com/codejamninja/donate) if you'd like to keep me going!

[![Liberapay receiving](https://img.shields.io/liberapay/receives/codejamninja.svg?style=flat-square)](https://liberapay.com/codejamninja/donate)
[![Liberapay patrons](https://img.shields.io/liberapay/patrons/codejamninja.svg?style=flat-square)](https://liberapay.com/codejamninja/donate)
