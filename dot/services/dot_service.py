from print_service import wait
from os import path, remove, symlink, unlink
from shutil import rmtree
from glob import glob
import yaml
import re
import sys

def clean():
    paths = [
        path.abspath(path.join(path.expanduser('~'), '.dotfiles'))
    ]
    location = get_prop('location', silent=True)
    if location:
        paths.append(location)
        for dotfile in get_dotfiles():
            link_name = path.join(path.expanduser('~'), dotfile)
            if path.islink(link_name):
                unlink(link_name)
    return wait('Cleaning . . .', lambda: run_clean(paths))

def run_clean(paths):
    for p in paths:
        if path.exists(p):
            if path.isfile(p):
                remove(p)
            else:
                rmtree(p)
    return True

def get_config():
    p = path.abspath(path.join(path.expanduser('~'), '.dotfiles'))
    if path.isfile(p):
        with open(p) as f:
            try:
                return yaml.load(f)
            except yaml.YAMLError as exc:
                return {}
    else:
        return {}

def update_config(prop, value):
    p = path.abspath(path.join(path.expanduser('~'), '.dotfiles'))
    config = get_config()
    config[prop] = value
    with open(p, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

def get_dotfiles():
    dotfiles = list()
    ignore_list = [
        '.gitignore',
        '.git',
        '.editorconfig',
        '.zshrc'
    ]
    location = get_prop('location')
    for p in glob((location + '/.*').replace('//', '/')):
        matches = re.findall(r'\/\..+', p)
        if len(matches) > 0:
            dotfile = matches[0][1:]
            ignore = False
            for i in ignore_list:
                if dotfile == i:
                    ignore = True
            if not ignore:
                dotfiles.append(dotfile)
    return dotfiles

def get_prop(prop_name, silent=None):
    config = get_config()
    if prop_name not in config:
        if silent:
            return None
        else:
            sys.stderr.write('Property \'' + prop_name + '\' missing from ~/.dotfiles config\n')
            return exit(1)
    return config[prop_name]

def symlink_dotfiles():
    return wait('Symlinking . . .', lambda: run_symlink_dotfiles())

def run_symlink_dotfiles():
    location = get_prop('location')
    symlinks = list()
    for dotfile in get_dotfiles():
        source = path.join(location, dotfile)
        link_name = path.join(path.expanduser('~'), dotfile)
        if not path.exists(link_name):
            if path.islink(link_name):
                unlink(link_name)
            symlink(source, link_name)
            symlinks.append((source, link_name))
    return symlinks
