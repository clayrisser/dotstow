import { Command, flags } from '@oclif/command';
import { Options } from '../types';
import { sync } from '../actions';

export default class Sync extends Command {
  static description = 'sync dotfiles';

  static examples = ['$ dotstow sync'];

  static flags = {
    config: flags.string({ char: 'c', required: false }),
    debug: flags.boolean({ char: 'd', required: false })
  };

  async run() {
    const { flags } = this.parse(Sync);
    const options: Options = {
      config: JSON.parse(flags.config || '{}'),
      debug: !!flags.debug
    };
    return sync(options);
  }
}
