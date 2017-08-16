from cement.core.controller import CementBaseController, expose

class AddController(CementBaseController):
    class Meta:
        label = 'add'
        description = 'Add and remove dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        print('adding and removing')
