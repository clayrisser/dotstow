import { Command, flags } from '@oclif/command';
import { Options } from '../types';
import { stow } from '../actions';

export default class Stow extends Command {
  static description = 'stow dotfiles';

  static examples = ['$ dotstow stow'];

  static flags = {
    config: flags.string({ char: 'c', required: false }),
    debug: flags.boolean({ char: 'd', required: false })
  };

  async run() {
    const { flags } = this.parse(Stow);
    const options: Options = {
      config: JSON.parse(flags.config || '{}'),
      debug: !!flags.debug
    };
    return stow(options);
  }
}
