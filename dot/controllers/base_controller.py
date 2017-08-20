from cement.core.controller import CementBaseController, expose

class BaseController(CementBaseController):
    class Meta:
        label = 'base'
        description = 'Manage your dot files'

    @expose(hide=True)
    def default(self):
        return
