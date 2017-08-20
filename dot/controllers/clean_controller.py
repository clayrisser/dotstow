from cement.core.controller import CementBaseController, expose
from dot.services import dot_service

class CleanController(CementBaseController):
    class Meta:
        label = 'clean'
        description = 'Clean dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'

    @expose(hide=True)
    def default(self):
        return dot_service.clean()
