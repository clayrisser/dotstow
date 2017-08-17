from cement.core.foundation import CementApp
from config import NAME, BANNER
from controllers import (
    AddController,
    BaseController,
    CleanController,
    CloneController,
    InitController,
    PullController,
    PushController
)

class App(CementApp):
    class Meta:
        label = NAME
        base_controller = BaseController
        handlers = [
            AddController,
            CleanController,
            CloneController,
            InitController,
            PullController,
            PushController
        ]

def main():
    with App() as app:
        print(BANNER)
        app.run()

if __name__ == '__main__':
    main()
