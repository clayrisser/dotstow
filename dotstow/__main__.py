import os, sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from dotstow import App

def main():
    with App() as app:
        app.run()

if __name__ == '__main__':
    main()
