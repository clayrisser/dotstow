from . import controllers, services
from cfoundation import create_app

App = create_app(
    name='dotstow',
    controllers=controllers,
    services=services,
    conf={
        'debug': False
    }
)
