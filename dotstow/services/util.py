from cfoundation import Service
from subprocess import check_output, CalledProcessError, STDOUT

class Util(Service):
    def subproc(self, command):
        c = self.app.conf
        log = self.app.log
        spinner = self.app.spinner
        log.debug('command: ' + command)
        try:
            stdout = check_output(
                command,
                stderr=STDOUT,
                shell=True
            ).decode('utf-8')
            log.debug(stdout)
            return stdout
        except CalledProcessError as err:
            if err.output:
                spinner.fail(err.output.decode('utf-8'))
            else:
                spinner.fail('subprocess command failed')
            if c.debug:
                raise err
            exit(1)
