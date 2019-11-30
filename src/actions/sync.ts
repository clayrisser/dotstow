import fs from 'fs-extra';
import ora from 'ora';
import path from 'path';
import { homedir } from 'os';
import { Git } from '../services';
import { Options } from '../types';

export default async function sync(options: Options = {}): Promise<any> {
  const dotfilesPath = path.resolve(homedir(), options.dotfiles || '.dotfiles');
  options.dotfiles = dotfilesPath;
  const spinner = ora();
  const git = new Git(options);
  try {
    if (await fs.pathExists(dotfilesPath)) {
      spinner.start('pulling dotfiles');
      await git.pull();
      spinner.succeed('pulled dotfiles');
    } else {
      const remote = options.remote || (await git.guessRemote());
      spinner.start('cloning dotfiles');
      await git.clone(remote);
      spinner.succeed('cloned dotfiles');
    }
    spinner.start('committing dotfiles');
    const message = await git.commit();
    if (message) {
      spinner.succeed(`committed dotfiles with message "${message}"`);
      spinner.start('pushing dotfiles');
      await git.push();
      spinner.succeed('pushed dotfiles');
    } else {
      spinner.warn('no files to commit');
    }
  } catch (err) {
    if (options.debug) throw err;
    spinner.fail(err.message);
  }
}
