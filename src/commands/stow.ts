import { Command, flags } from '@oclif/command';
import { Options } from '../types';
import { stow } from '../actions';

export default class Stow extends Command {
  static description = 'stow dotfiles';

  static examples = ['$ dotstow stow'];

  static flags = {
    debug: flags.boolean({ required: false }),
    dotfiles: flags.string({ char: 'd', required: false }),
    environment: flags.string({ char: 'e', required: false }),
    force: flags.boolean({ char: 'f', required: false }),
    sync: flags.boolean({ char: 's', required: false })
  };

  static strict = false;

  static args = [{ name: 'PACKAGES...', required: true }];

  async run() {
    const { flags } = this.parse(Stow);
    const options: Options = {
      debug: !!flags.debug,
      dotfiles: flags.dotfiles,
      environment: flags.environment,
      force: !!flags.force,
      sync: !!flags.sync
    };
    return stow(
      options,
      this.argv.filter((arg: string) => arg[0] !== '-')
    );
  }
}
