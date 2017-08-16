from cement.core.controller import CementBaseController, expose

class InitController(CementBaseController):
    class Meta:
        label = 'init'
        description = 'Initialize dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        print('initing')
