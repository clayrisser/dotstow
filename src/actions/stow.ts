import { Options } from '../types';
import { Stow } from '../services';

export default async function stow(options: Options = {}): Promise<any> {
  const stow = new Stow(options);
  await stow.stow([]);
  return options;
}
