'use strict';

const EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function (defaults) {
  const app = new EmberApp(defaults, {
    emberData: {
      deprecations: {
        // New projects can safely leave this deprecation disabled.
        // If upgrading, to opt-into the deprecated behavior, set this to true and then follow:
        // https://deprecations.emberjs.com/id/ember-data-deprecate-store-extends-ember-object
        // before upgrading to Ember Data 6.0
        DEPRECATE_STORE_EXTENDS_EMBER_OBJECT: false,
      },
    },

    'ember-cli-babel': { enableTypeScriptTransform: true },

    babel: {
      plugins: [require.resolve('ember-concurrency/async-arrow-task-transform')],
    },

    svgJar: {
      sourceDirs: ['node_modules/@primer/octicons/build/svg'],
    },
  });

  app.import('node_modules/@primer/octicons/build/build.css');
  app.import('node_modules/bootstrap/dist/css/bootstrap.css');

  return app.toTree();
};
