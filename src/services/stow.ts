import execa from 'execa';
import path from 'path';
import { homedir } from 'os';
import { Options } from '../types';

export default class Stow {
  dotfilesPath: string;

  constructor(public options: Options = {}) {
    this.dotfilesPath = path.resolve(
      homedir(),
      this.options.dotfiles || '.dotfiles'
    );
  }

  async stow(packages: string[]) {
    await execa(
      'stow',
      ['-t', homedir(), '-d', this.dotfilesPath, ...packages],
      {
        stdio: 'inherit'
      }
    );
  }
}
