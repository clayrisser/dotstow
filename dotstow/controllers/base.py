from cement.core.controller import expose
from cfoundation import Controller

class Base(Controller):
    class Meta:
        label = 'base'
        description = 'manage dotfiles with stow'
        arguments = [
            (['packages'], {
                'action': 'store',
                'help': 'dotfile package names',
                'nargs': '*'
            })
        ]

    @expose()
    def default(self):
        pargs = self.app.pargs
        s = self.app.services
        spinner = self.app.spinner
        if pargs.debug:
            self.app.conf.debug = True
        if not pargs.packages or len(pargs.packages) <= 0:
            spinner.fail('dotfile packages not specified')
            exit(0)
        s.stow.stow(pargs.packages)
        spinner.succeed('stowed ' + ' '.join(pargs.packages))
