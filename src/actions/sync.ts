import { Git } from '../services';
import { Options } from '../types';

export default async function sync(options: Options = {}): Promise<any> {
  const git = new Git(options);
  console.log('pulling');
  await git.pull();
  console.log('commiting');
  await git.commit();
  console.log('pushing');
  await git.push();
  return options;
}
