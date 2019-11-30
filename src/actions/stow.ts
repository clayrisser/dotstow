import ora from 'ora';
import { Options } from '../types';
import { Stow } from '../services';

export default async function stow(
  options: Options = {},
  packages: string[]
): Promise<any> {
  const spinner = ora();
  spinner.start(`stowing packages '${packages.join("' '")}'`);
  try {
    const stow = new Stow(options);
    await stow.stow(packages);
    spinner.succeed(`stowed packages '${packages.join("' '")}'`);
  } catch (err) {
    if (err.code?.toString()?.[0] === '4') {
      spinner.fail(err.message);
    } else {
      throw err;
    }
  }
}
