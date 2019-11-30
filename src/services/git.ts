import path from 'path';
import { Clone, Cred, Diff, Repository, Signature } from 'nodegit';
import { createInterface as createReadlineInterface } from 'readline';
import { homedir, userInfo } from 'os';
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
    await Clone.clone(remote, this.dotfilesPath, {
      fetchOpts: { callbacks: { credentials: getCredentials() } }
    });
  }

  async commit(message?: string): Promise<string | null> {
    const repo = await Repository.open(this.dotfilesPath);
    const signature = await ((Signature.default(repo) as unknown) as Promise<
      Signature
    >);
    const index = await repo.refreshIndex();
    const head = await repo.getHeadCommit();
    if (!(await repo.getStatus()).length) return null;
    await index.addAll();
    index.write();
    const oid = await index.writeTree();
    if (!message) {
      const diff = await Diff.treeToIndex(repo, await head.getTree());
      message = `Updated ${
        (await diff.patches()).map(patch => patch.newFile().path())?.[0]
      }`;
    }
    await repo.createCommit(
      'HEAD',
      signature,
      signature,
      message || 'updated dotfiles',
      oid,
      [await repo.getCommit(head)]
    );
    return message;
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

  async guessRemote(): Promise<string> {
    const githubUsername = await new Promise<string>(resolve => {
      const readline = createReadlineInterface({
        input: process.stdin,
        output: process.stdout
      });
      const defaultGithubUsername = userInfo().username;
      readline.question(
        `github username (${defaultGithubUsername}): `,
        (githubUsername: string) => {
          readline.close();
          return resolve(githubUsername || defaultGithubUsername);
        }
      );
    });
    return new Promise<string>(resolve => {
      const readline = createReadlineInterface({
        input: process.stdin,
        output: process.stdout
      });
      const defaultRemote = `git@github.com:${githubUsername}/dotfiles.git`;
      readline.question(
        `dotfiles remote (${defaultRemote}): `,
        (remote: string) => {
          readline.close();
          return resolve(remote || defaultRemote);
        }
      );
    });
  }
}
