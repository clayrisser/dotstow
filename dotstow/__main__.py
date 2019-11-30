import os, sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from dotstow import App
import warnings

warnings.warn('''
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
''', DeprecationWarning,
              stacklevel=2)

def main():
    with App() as app:
        app.run()

if __name__ == '__main__':
    main()
