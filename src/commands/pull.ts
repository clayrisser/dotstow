import { Command, flags } from '@oclif/command';
import { Options } from '../types';
import { pull } from '../actions';

export default class Pull extends Command {
  static description = 'pull dotfiles';

  static examples = ['$ dotstow pull'];

  static flags = {
    debug: flags.boolean({ char: 'd', required: false }),
  };

  async run() {
    const { flags } = this.parse(Pull);
    const options: Options = {
      debug: !!flags.debug,
    };
    return pull(options);
  }
}
