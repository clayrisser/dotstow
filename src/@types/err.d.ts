declare module 'err' {
  class Err extends Error {
    constructor(message: Err | string, code?: number | string);

    code: number | string;
  }
  export = Err;
}
