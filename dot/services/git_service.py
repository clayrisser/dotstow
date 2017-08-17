from git import Repo
from print_service import wait
from pyspin.spin import Default, make_spin
from dot_service import update_config
import os
import sys

def clone(origin=None, location=None, github_user=None, github_repo=None, http=None):
    if github_user:
        base = 'git@github.com:'
        if http:
            base = 'https://github.com/'
        origin = base + github_user + '/' + github_repo + '.git'
    if not location:
        location = os.getcwd()
    if not os.path.exists(location):
        os.makedirs(location)
    repo = wait('Cloning . . .', lambda: Repo.clone_from(origin, location))
    if Repo.init(location).__class__ is Repo:
        update_config('location', location)
        return repo
    else:
        sys.stderr.write('Failed to clone dotfiles')
        return exit(1)

def push():
    pass

def pull():
    pass

def add():
    pass
