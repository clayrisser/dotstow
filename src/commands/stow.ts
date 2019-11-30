import { Command, flags } from '@oclif/command';
import { Options } from '../types';
import { stow } from '../actions';

export default class Stow extends Command {
  static description = 'stow dotfiles';

  static examples = ['$ dotstow stow'];

  static flags = {
    debug: flags.boolean({ required: false }),
    dotfiles: flags.string({ char: 'd', required: false })
  };

  async run() {
    const { flags } = this.parse(Stow);
    const options: Options = {
      debug: !!flags.debug,
      dotfiles: flags.dotfiles
    };
    return stow(options);
  }
}
