import fs from 'fs-extra';

export interface OSInfo {
  aix: boolean;
  amigaos: boolean;
  android: boolean;
  beos: boolean;
  bsd: boolean;
  centos: boolean;
  darwin: boolean;
  debian: boolean;
  fedora: boolean;
  freebsd: boolean;
  ios: boolean;
  linux: boolean;
  mac: boolean;
  nintendo: boolean;
  openbsd: boolean;
  osx: boolean;
  redhat: boolean;
  rhel: boolean;
  slackware: boolean;
  starBlade: boolean;
  sunos: boolean;
  ubuntu: boolean;
  unix: boolean;
  value: string;
  win32: boolean;
  win64: boolean;
  win: boolean;
  windows: boolean;
}

export default class OS {
  get slackware(): boolean {
    return this.value === 'slackware';
  }

  get starBlade(): boolean {
    return this.value === 'star-blade';
  }

  get redhat(): boolean {
    return this.value === 'redhat';
  }

  get sunos(): boolean {
    return this.value === 'sunos';
  }

  get ubuntu(): boolean {
    return this.value === 'ubuntu';
  }

  get wii(): boolean {
    return this.value === 'wii';
  }

  get win32(): boolean {
    return this.value === 'win32';
  }

  get win64(): boolean {
    return this.value === 'win64';
  }

  get aix(): boolean {
    return this.value === 'aix';
  }

  get amigaos(): boolean {
    return this.value === 'amigaos';
  }

  get android(): boolean {
    return this.value === 'android';
  }

  get beos(): boolean {
    return this.value === 'beos';
  }

  get centos(): boolean {
    return this.value === 'centos';
  }

  get fedora(): boolean {
    return this.value === 'fedora';
  }

  get freebsd(): boolean {
    return this.value === 'freebsd';
  }

  get ios(): boolean {
    return this.value === 'ios';
  }

  get mac(): boolean {
    return this.value === 'mac';
  }

  get debian(): boolean {
    return this.ubuntu || this.value === 'debian';
  }

  get nintendo(): boolean {
    return this.value === 'nintendo' || this.wii;
  }

  get openbsd(): boolean {
    return this.value === 'openbsd';
  }

  get linux(): boolean {
    if (this.rhel) return true;
    if (this.debian) return true;
    if (this.android) return true;
    if (this.slackware) return true;
    if (this.value === 'linux') return true;
    return false;
  }

  get bsd(): boolean {
    return this.freebsd || this.openbsd;
  }

  get darwin(): boolean {
    return this.ios || this.mac;
  }

  get osx(): boolean {
    return this.mac;
  }

  get rhel(): boolean {
    return this.redhat || this.centos || this.fedora;
  }

  get win(): boolean {
    return this.win32 || this.win64;
  }

  get windows(): boolean {
    return this.win;
  }

  get unix(): boolean {
    if (this.linux) return true;
    if (this.darwin) return true;
    if (this.bsd) return true;
    if (this.aix) return true;
    if (this.sunos) return true;
    return false;
  }

  get info(): OSInfo {
    return {
      aix: this.aix,
      amigaos: this.amigaos,
      android: this.android,
      beos: this.beos,
      bsd: this.bsd,
      centos: this.centos,
      darwin: this.darwin,
      debian: this.debian,
      fedora: this.fedora,
      freebsd: this.freebsd,
      ios: this.ios,
      linux: this.linux,
      mac: this.mac,
      nintendo: this.nintendo,
      openbsd: this.openbsd,
      osx: this.osx,
      redhat: this.redhat,
      rhel: this.rhel,
      slackware: this.slackware,
      starBlade: this.starBlade,
      sunos: this.sunos,
      ubuntu: this.ubuntu,
      unix: this.unix,
      value: this.value,
      win32: this.win32,
      win64: this.win64,
      win: this.win,
      windows: this.windows
    };
  }

  get value(): string {
    let release = '';
    try {
      release = fs
        .readFileSync('/etc/os-release')
        .toString()
        .toLowerCase();
    } catch (err) {
      release = '';
    }
    if (/ubuntu/i.test(release)) {
      return 'ubuntu';
    }
    if (/debian/i.test(release)) {
      return 'debian';
    }
    if (/centos/i.test(release)) {
      return 'centos';
    }
    if (/fedora/i.test(release)) {
      return 'fedora';
    }
    if (/red\shat/i.test(release)) {
      return 'redhat';
    }
    if (process.platform && process.platform.length) {
      if (
        process.platform === 'win32' &&
        (/64/.test(process.arch) || process.env.PROCESSOR_ARCHITEW6432)
      ) {
        return 'win64';
      }
      if (process.platform === 'darwin') return 'mac';
      return process.platform;
    }
    return 'unknown';
  }
}
