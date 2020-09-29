import Err from 'err';
import execa from 'execa';
import fs from 'fs-extra';
import path from 'path';
import { homedir, hostname } from 'os';
import { mapSeries } from 'bluebird';
import { Options } from '../types';
import { OS } from '.';

const bootstrapConfigName = 'bootstrap.yml';

export { bootstrapConfigName };

export default class Stow {
  dotfilesPath: string;

  _platforms: string[];

  constructor(public options: Options = {}) {
    this.dotfilesPath = path.resolve(
      homedir(),
      this.options.dotfiles || '.dotfiles'
    );
  }

  get packages(): string[] {
    return fs.readdirSync(this.dotfilesPath).filter((name: string) => {
      if (!name.length || name[0] === '.' || name[0] === '_') {
        return false;
      }
      return fs.statSync(path.resolve(this.dotfilesPath, name)).isDirectory();
    });
  }

  get platforms(): string[] {
    if (this._platforms) return this._platforms;
    const os = new OS();
    this._platforms = [
      ...new Set([
        os.value,
        ...Object.entries(os.info).reduce(
          (
            platforms: string[],
            [platform, value]: [string, boolean | string]
          ) => {
            if (value === true) platforms.push(platform);
            return platforms;
          },
          []
        )
      ])
    ];
    return this._platforms;
  }

  containsPackage(environment: string, packageName?: string): boolean {
    if (!packageName) return true;
    return fs.pathExistsSync(
      path.resolve(this.dotfilesPath, environment, packageName)
    );
  }

  containsConfig(environment: string, configName: string): boolean {
    return fs.pathExistsSync(
      path.resolve(this.dotfilesPath, environment, configName)
    );
  }

  getEnvironment(packageName?: string): string {
    const environments = fs
      .readdirSync(this.dotfilesPath)
      .filter((name: string) => {
        if (!name.length || name[0] === '.' || name[0] === '_') {
          return false;
        }
        return fs.statSync(path.resolve(this.dotfilesPath, name)).isDirectory();
      });
    if (!environments.length) throw new Err('please create an environment');
    if (
      this.options.environment &&
      environments.includes(this.options.environment) &&
      this.containsPackage(this.options.environment, packageName)
    ) {
      return this.options.environment;
    }
    if (
      environments.includes(hostname()) &&
      this.containsPackage(hostname(), packageName)
    ) {
      return hostname();
    }
    for (let i = 0; i < this.platforms.length; i++) {
      if (
        environments.includes(this.platforms?.[i]) &&
        this.containsPackage(this.platforms?.[i], packageName)
      ) {
        return this.platforms[i];
      }
    }
    if (
      environments.includes('global') &&
      this.containsPackage('global', packageName)
    ) {
      return 'global';
    }
    if (!this.containsPackage('global', packageName)) {
      throw new Err(`package '${packageName}' not found`, 404);
    }
    return environments[0];
  }

  getBootstrapEnvironment(): string {
    const environments = fs
      .readdirSync(this.dotfilesPath)
      .filter((name: string) => {
        if (!name.length || name[0] === '.' || name[0] === '_') {
          return false;
        }
        return fs.statSync(path.resolve(this.dotfilesPath, name)).isDirectory();
      });
    if (!environments.length) throw new Err('please create an environment');
    if (
      this.options.environment &&
      environments.includes(this.options.environment) &&
      this.containsConfig(this.options.environment, bootstrapConfigName)
    ) {
      return this.options.environment;
    }
    if (
      environments.includes(hostname()) &&
      this.containsConfig(hostname(), bootstrapConfigName)
    ) {
      return hostname();
    }
    for (let i = 0; i < this.platforms.length; i++) {
      if (
        environments.includes(this.platforms?.[i]) &&
        this.containsConfig(this.platforms?.[i], bootstrapConfigName)
      ) {
        return this.platforms[i];
      }
    }
    if (
      environments.includes('global') &&
      this.containsConfig('global', bootstrapConfigName)
    ) {
      return 'global';
    }
    if (!this.containsConfig('global', bootstrapConfigName)) {
      throw new Err(`${bootstrapConfigName} not found`, 404);
    }
    return '';
  }

  async stow(packages: string[]) {
    await mapSeries(packages, async (packageName: string) => {
      const environment = this.getEnvironment(packageName);
      return this.stowPackage(environment, packageName);
    });
  }

  async stowPackage(environment: string, packageName: string) {
    try {
      await execa(
        'stow',
        [
          '-t',
          homedir(),
          '-d',
          path.resolve(this.dotfilesPath, environment),
          packageName
        ],
        {
          stdio: this.options.debug ? 'inherit' : 'pipe'
        }
      );
    } catch (err) {
      if (
        err.stderr?.indexOf('existing target is') > -1 &&
        this.options.force
      ) {
        const regex = /existing\starget\sis\s.+:\s(.*)\n/g;
        let matches = null;
        const files = [];
        // eslint-disable-next-line no-cond-assign
        while ((matches = regex.exec(err.stderr || '')) !== null) {
          files.push(matches[1]);
          regex.lastIndex++;
        }
        await mapSeries(files, async (file) => {
          const filePath = path.resolve(homedir(), file);
          await fs.unlink(filePath);
        });
        await this.stowPackage(environment, packageName);
      } else {
        if (err.stderr) throw new Err(err.stderr, 400);
        throw err;
      }
    }
  }
}
