from print_service import wait
from os import path
from shutil import rmtree
from os import remove
import yaml

def clean():
    paths = [
        path.abspath(path.join(path.expanduser('~'), '.dotfiles'))
    ]
    config = get_config()
    if 'location' in config:
        paths.append(config['location'])
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
