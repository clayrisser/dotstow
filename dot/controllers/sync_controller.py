from cement.core.controller import CementBaseController, expose
from dot.services import dot_service, git_service

class SyncController(CementBaseController):
    class Meta:
        label = 'sync'
        description = 'Sync dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        git_service.pull()
        dot_service.symlink_dotfiles()
        git_service.push()
