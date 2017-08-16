from cement.core.foundation import CementApp
from controllers import (
    AddController,
    BaseController,
    CloneController,
    InitController,
    PullController,
    PushController
)

VERSION = '0.0.0'

BANNER = """
dot v%s
Copyright (c) 2017 Jam Risser
""" % VERSION

class App(CementApp):
    class Meta:
        label = 'dot'
        base_controller = BaseController
        handlers = [
            AddController,
            CloneController,
            InitController,
            PullController,
            PushController
        ]

def main():
    with App() as app:
        app.run()

if __name__ == '__main__':
    main()
