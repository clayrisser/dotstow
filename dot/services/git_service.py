from git import Repo
from print_service import wait
from pyspin.spin import Default, make_spin

def clone(origin=None, location=None, github_user=None, github_repo=None, ssh=None):
    if github_user:
        base = 'git@github.com:'
        if not ssh:
            base = 'https://github.com/'
        origin = base + github_user + '/' + github_repo + '.git'
    if not location:
        location = os.getcwd()
    return wait('Cloning . . .', lambda: Repo.clone_from(origin, location))

def push():
    pass

def pull():
    pass

def add():
    pass
