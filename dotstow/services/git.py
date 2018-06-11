from cfoundation import Service
from git import Repo
from os import path
import getpass
import os

class Git(Service):
    def sync(self):
        s = self.app.services
        spinner = self.app.spinner
        home_path = path.expanduser("~")
        dotfiles_path = path.join(home_path, '.dotfiles')
        spinner.start('syncing dotfiles')
        if not path.isdir(dotfiles_path):
            repo = s.util.prompt('dotfiles repo', self.guess_repo())
            self.clone(repo)
        self.pull()
        self.commit()
        self.push()
        spinner.succeed('synced dotfiles')

    def clone(self, repo):
        spinner = self.app.spinner
        home_path = path.expanduser("~")
        dotfiles_path = path.join(home_path, '.dotfiles')
        spinner.start('cloning dotfiles to ~/.dotfiles')
        if not path.isdir(dotfiles_path):
            if path.exists(dotfiles_path):
                spinner.fail('please remove ~/.dotfiles')
                exit(1)
            os.makedirs(dotfiles_path)
        result = Repo.clone_from(repo, dotfiles_path)
        spinner.succeed('cloned dotfiles to ~/.dotfiles')
        return result

    def commit(self, message=None):
        spinner = self.app.spinner
        home_path = path.expanduser("~")
        dotfiles_path = path.join(home_path, '.dotfiles')
        if not path.isdir(dotfiles_path):
            spinner.fail('missing dotfiles repo')
            exit(1)
        repo = Repo(dotfiles_path)
        repo.git.add(A=True)
        if len(repo.index.diff(repo.head.commit)) > 0:
            message = 'Updated ' + repo.index.diff(repo.head.commit)[0].a_path
            spinner.start('committing dotfiles "' + message + '"')
            result = repo.git.commit(message=message)
            spinner.succeed('committed dotfiles with message "' + message + '"')

    def pull(self):
        spinner = self.app.spinner
        home_path = path.expanduser("~")
        dotfiles_path = path.join(home_path, '.dotfiles')
        spinner.start('pulling dotfiles')
        if not path.isdir(dotfiles_path):
            spinner.fail('missing dotfiles repo')
            exit(1)
        repo = Repo(dotfiles_path)
        result = repo.git.pull()
        spinner.succeed('pulled dotfiles')
        return result

    def push(self):
        spinner = self.app.spinner
        home_path = path.expanduser("~")
        dotfiles_path = path.join(home_path, '.dotfiles')
        spinner.start('pushing dotfiles')
        if not path.isdir(dotfiles_path):
            spinner.fail('missing dotfiles repo')
            exit(1)
        repo = Repo(dotfiles_path)
        result = repo.git.push()
        spinner.succeed('pushed dotfiles')
        return result

    def guess_repo(self):
        s = self.app.services
        base = 'git@github.com:'
        github_user = s.util.prompt('github user', getpass.getuser())
        return base + github_user + '/dotfiles.git'
