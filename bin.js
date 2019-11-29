#!/usr/bin/env node

require('@babel/polyfill');
if (require.main === module) {
  require('./lib/bin');
} else {
  throw new Error("module 'bin' cannot be imported");
}
