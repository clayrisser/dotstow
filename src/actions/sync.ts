import { Options } from '../types';

export default async function sync(options: Options = {}): Promise<any> {
  console.log('syncing');
  return options;
}
