from cfoundation import Service
from os import path

class Stow(Service):
    def stow(self, packages):
        s = self.app.services
        home_path = path.expanduser("~")
        dotfiles_path = path.join(home_path, '.dotfiles')
        s.util.subproc('stow -t ' + home_path + ' -d ' + dotfiles_path + ' ' + ' '.join(packages))
