from pyspin.spin import Default, make_spin
import time

def wait(message, cb):
    @make_spin(Default, message)
    def wait():
        return cb()
    return wait()
