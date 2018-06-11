from cfoundation import Service
from subprocess import check_output, CalledProcessError, STDOUT
from munch import munchify
import inquirer

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


    def prompt(self, message, default=None):
        spinner = self.app.spinner
        answers = None
        spinner.stop()
        if not default:
            answers = munchify(inquirer.prompt([inquirer.Text('answer', message=message)]))
        else:
            answers = munchify(inquirer.prompt([inquirer.Text('answer', message=message + ' (' + default + ')')]))
        spinner.start()
        if answers.answer and len(answers.answer) > 0:
            return answers.answer
        return default
