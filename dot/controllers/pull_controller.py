from cement.core.controller import CementBaseController, expose
from dot.services import git_service

class PullController(CementBaseController):
    class Meta:
        label = 'pull'
        description = 'Pull dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        git_service.pull()
