from git import Repo
from print_service import wait
from pyspin.spin import Default, make_spin
from dot_service import update_config, get_prop
import os
from urllib import quote
import sys
from time import sleep

def clone(origin=None, location=None, github_user=None, github_repo=None, github_password='', http=None):
    if github_user:
        base = 'git@github.com:'
        if http:
            base = 'https://' + quote(github_user) + ':' + quote(github_password) + '@github.com/'
        origin = base + github_user + '/' + github_repo + '.git'
    print(origin)
    if not location:
        location = os.getcwd()
    if not os.path.exists(location):
        os.makedirs(location)
    repo = wait('Cloning . . .', lambda: Repo.clone_from(origin, location))
    if Repo.init(location).__class__ is Repo:
        update_config('location', location)
        return repo
    else:
        sys.stderr.write('Failed to clone dotfiles\n')
        return exit(1)

def push():
    stage()
    commit()
    repo = Repo(get_prop('location'))
    return wait('Pushing . . .', lambda: repo.git.push())

def pull():
    stage()
    commit()
    repo = Repo(get_prop('location'))
    return wait('Pulling . . .', lambda: repo.git.pull())

def stage():
    repo = Repo(get_prop('location'))
    return wait('Staging . . .', lambda: repo.git.add(A=True))

def commit(message=None):
    repo = Repo(get_prop('location'))
    if len(repo.index.diff(repo.head.commit)) > 0:
        if not message:
            message = 'Updated ' + repo.index.diff(repo.head.commit)[0].a_path
        def run_commit():
            return repo.git.commit(message=message)
    else:
        def run_commit():
            return
    return wait('Commiting . . .', lambda: run_commit())
