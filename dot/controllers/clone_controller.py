from cement.core.controller import CementBaseController, expose

class CloneController(CementBaseController):
    class Meta:
        label = 'clone'
        description = 'Clone dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        print('cloning')
