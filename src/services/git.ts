import path from 'path';
import { Clone, Cred, Reference, Repository, Signature } from 'nodegit';
import { homedir } from 'os';
import { Options } from '../types';

function getCredentials() {
  let debug = 0;
  return (_url: string, userName: string) => {
    if (debug++ > 10) {
      return Cred.sshKeyNew(
        userName,
        path.resolve(homedir(), '.ssh/id_rsa.pub'),
        path.resolve(homedir(), '.ssh/id_rsa'),
        ''
      );
    }
    return Cred.sshKeyFromAgent(userName);
  };
}

export default class Git {
  dotfilesPath: string;

  remote = 'origin';

  branch: string;

  constructor(public options: Options = {}) {
    this.dotfilesPath = path.resolve(
      homedir(),
      this.options.dotfiles || '.dotfiles'
    );
    this.branch = options.branch || 'master';
  }

  async clone(remote: string) {
    await Clone.clone(remote, this.dotfilesPath);
  }

  async commit(message?: string) {
    const repo = await Repository.open(this.dotfilesPath);
    const signature = await ((Signature.default(repo) as unknown) as Promise<
      Signature
    >);
    const index = await repo.refreshIndex();
    await index.addAll();
    index.write();
    const oid = await index.writeTree();
    await repo.createCommit(
      'HEAD',
      signature,
      signature,
      message || 'updated dotfiles',
      oid,
      [await repo.getCommit(await Reference.nameToId(repo, 'HEAD'))]
    );
  }

  async pull(branch = this.branch) {
    const repo = await Repository.open(this.dotfilesPath);
    await repo.fetchAll({
      callbacks: { credentials: getCredentials() }
    });
    await repo.mergeBranches(branch, `${this.remote}/${branch}`);
  }

  async push(branch = this.branch) {
    const repo = await Repository.open(this.dotfilesPath);
    const remote = await repo.getRemote(this.remote);
    await remote.push([`refs/heads/${branch}:refs/heads/${branch}`], {
      callbacks: { credentials: getCredentials() }
    });
  }
}
