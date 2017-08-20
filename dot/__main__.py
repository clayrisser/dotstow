from cement.core.foundation import CementApp
from config import NAME, BANNER
from controllers import (
    BaseController,
    CleanController,
    CloneController,
    PullController,
    PushController,
    StageController,
    SymlinkController,
    SyncController
)

class App(CementApp):
    class Meta:
        label = NAME
        base_controller = BaseController
        handlers = [
            CleanController,
            CloneController,
            PullController,
            PushController,
            StageController,
            SymlinkController,
            SyncController
        ]

def main():
    with App() as app:
        print(BANNER)
        app.run()

if __name__ == '__main__':
    main()
