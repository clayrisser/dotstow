# dotstow

[![GitHub stars](https://img.shields.io/github/stars/codejamninja/dotstow.svg?style=social&label=Stars)](https://github.com/codejamninja/dotstow)

> Manage dotfiles with stow

Please ★ this repo if you found it useful ★ ★ ★


## Features

* Group dotfiles into units (stow packages)
* Automatically symlink (stow) files
* Backup dotfiles with git
* Powered by [GNU Stow](https://www.gnu.org/software/stow/)


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
