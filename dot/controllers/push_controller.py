from cement.core.controller import CementBaseController, expose

class PushController(CementBaseController):
    class Meta:
        label = 'push'
        description = 'Push dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        print('pushing')
