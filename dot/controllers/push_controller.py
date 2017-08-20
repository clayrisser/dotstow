from cement.core.controller import CementBaseController, expose
from dot.services import git_service

class PushController(CementBaseController):
    class Meta:
        label = 'push'
        description = 'Push dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        git_service.push()
