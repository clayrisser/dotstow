from cement.core.controller import CementBaseController, expose
from services import dot_service

class SymlinkController(CementBaseController):
    class Meta:
        label = 'symlink'
        description = 'Symlic dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        dot_service.symlink_dotfiles()
