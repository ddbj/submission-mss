'use strict';
const EmberApp = require('ember-cli/lib/broccoli/ember-app');

const { compatBuild } = require('@embroider/compat');

module.exports = async function (defaults) {
  const { buildOnce } = await import('@embroider/vite');
  const { setConfig } = await import('@warp-drive/build-config');

  const app = new EmberApp(defaults, {
    'ember-cli-babel': { enableTypeScriptTransform: true },

    babel: {
      plugins: [require.resolve('ember-concurrency/async-arrow-task-transform')],
    },

    svgJar: {
      sourceDirs: ['node_modules/@primer/octicons/build/svg'],
    },
  });

  setConfig(app, __dirname, {
    deprecations: {
      DEPRECATE_STORE_EXTENDS_EMBER_OBJECT: false,
    },
  });

  return compatBuild(app, buildOnce);
};
