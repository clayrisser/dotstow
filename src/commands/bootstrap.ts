import { Command, flags } from '@oclif/command';
import { Options } from '../types';
import { bootstrap } from '../actions';

export default class Bootstrap extends Command {
  static description = 'bootstrap dotfiles';

  static examples = ['$ dotstow bootstrap'];

  static flags = {
    debug: flags.boolean({ required: false }),
    remote: flags.string({ char: 'r', required: false }),
    environment: flags.string({ char: 'e', required: false }),
    dotfiles: flags.string({ char: 'd', required: false })
  };

  async run() {
    const { flags } = this.parse(Bootstrap);
    const options: Options = {
      debug: !!flags.debug,
      remote: flags.remote,
      dotfiles: flags.dotfiles,
      environment: flags.environment
    };
    return bootstrap(options);
  }
}
