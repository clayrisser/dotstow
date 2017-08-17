from cement.core.controller import CementBaseController, expose
from services import git_service, dot_service
from six.moves import input
import os
import getpass

class CloneController(CementBaseController):
    class Meta:
        label = 'clone'
        description = 'Clone dotfiles'
        stacked_on = 'base'
        stacked_type = 'nested'
        arguments = [
            (['-u', '--user'], {
                'action': 'store',
                'dest': 'user',
                'help': 'GitHub user'
            }),
            (['-r', '--repo'], {
                'action': 'store',
                'dest': 'repo',
                'help': 'GitHub repo'
            }),
            (['-l', '--location'], {
                'action': 'store',
                'dest': 'location',
                'help': 'dotfiles location'
            }),
            (['-s', '--http'], {
                'action': 'store_true',
                'dest': 'http',
                'help': 'Use http instead of ssh'
            })
        ]

    @expose(hide=True)
    def default(self):
        pargs = self.app.pargs
        github_user = pargs.user
        if not github_user:
            github_user = input('GitHub User [' + getpass.getuser() + ']: ')
        github_user = getpass.getuser()
        github_repo = pargs.repo
        if not github_repo:
            github_repo = input('GitHub Repo [dotfiles]: ')
        if not github_repo:
            github_repo = 'dotfiles'
        location = pargs.location
        if not location:
            location = input('Location [' + os.getcwd() + ']: ')
        if not location:
            location = os.getcwd()
        git_service.clone(
            github_user=github_user,
            github_repo=github_repo,
            location=location,
            http=pargs.http
        )
        return dot_service.symlink_dotfiles()
