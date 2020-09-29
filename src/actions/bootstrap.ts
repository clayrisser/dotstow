import execa from 'execa';
import fs from 'fs-extra';
import ora from 'ora';
import path from 'path';
import YAML from 'yaml';
import { homedir } from 'os';
import { Git, Stow } from '../services';
import { Options } from '../types';
import { bootstrapConfigName } from '../services/stow';

export default async function bootstrap(options: Options = {}): Promise<any> {
  const dotfilesPath = path.resolve(homedir(), options.dotfiles || '.dotfiles');
  options.dotfiles = dotfilesPath;
  const spinner = ora();
  const git = new Git(options);

  try {
    if (await fs.pathExists(dotfilesPath)) {
      spinner.warn(
        `dotfiles directory exists at ${dotfilesPath}! Skipping cloning the remote repo!`
      );
    } else {
      const remote = options.remote || (await git.guessRemote());
      spinner.start('cloning dotfiles');
      await git.clone(remote);
      spinner.succeed('cloned dotfiles');
    }

    const stow = new Stow(options);
    const bootstrapEnv = stow.getBootstrapEnvironment();

    const bootstrapConfigFile = fs.readFileSync(
      path.resolve(dotfilesPath, bootstrapEnv, bootstrapConfigName),
      'utf8'
    );

    try {
      const bootstrapConfig = YAML.parse(bootstrapConfigFile);

      bootstrapConfig.forEach(async (element: any) => {
        if ('cmd' in element && 'message' in element) {
          spinner.start(`${element.message}`);
          try {
            await execa.command(element.cmd, { shell: true });
            spinner.succeed(`${element.message}: Done`);
          } catch (err) {
            spinner.fail(`${element.message} : Failed (${err.stderr})`);
          }
        } else {
          spinner.warn(
            'Both message and cmd should be present in the bootstrap.yml config file'
          );
        }
      });
    } catch (err) {
      if (`${bootstrapConfigName} not found` in err.message && options.debug) {
        spinner.warn(`${bootstrapConfigName} not found. Ignore bootstraping`);
      } else {
        if (options.debug) throw err;
        spinner.fail(err.message);
      }
    }
  } catch (err) {
    spinner.fail(err.message);
  }
}
