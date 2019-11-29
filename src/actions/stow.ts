import { Options } from '../types';

export default async function stow(options: Options = {}): Promise<any> {
  console.log('stowing');
  return options;
}
