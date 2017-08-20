from cement.core.controller import CementBaseController, expose
from dot.services import git_service

class StageController(CementBaseController):
    class Meta:
        label = 'stage'
        description = 'Stage dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        git_service.stage()
