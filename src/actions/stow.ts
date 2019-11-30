import ora from 'ora';
import { Options } from '../types';
import { Stow } from '../services';
import { sync } from '.';

export default async function stow(
  options: Options = {},
  packages: string[]
): Promise<any> {
  const spinner = ora();
  if (options.sync) await sync(options);
  try {
    spinner.start(`stowing packages '${packages.join("' '")}'`);
    const stow = new Stow(options);
    await stow.stow(packages);
    spinner.succeed(`stowed packages '${packages.join("' '")}'`);
  } catch (err) {
    if (options.debug) throw err;
    spinner.fail(err.message);
  }
}
