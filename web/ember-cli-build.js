'use strict';

const EmberApp = require('ember-cli/lib/broccoli/ember-app');

const funnel = require('broccoli-funnel');

module.exports = function (defaults) {
  const app = new EmberApp(defaults, {
    'ember-cli-babel': {
      enableTypeScriptTransform: true,
    },

    babel: {
      plugins: [require.resolve('ember-concurrency/async-arrow-task-transform')],
    },

    svgJar: {
      sourceDirs: ['node_modules/@primer/octicons/build/svg'],
    },
  });

  app.import('node_modules/@primer/octicons/build/build.css');
  app.import('node_modules/bootstrap/dist/css/bootstrap.css');

  const sourcemaps = funnel('node_modules/bootstrap', {
    srcDir: 'dist/css',
    destDir: 'assets',
    include: ['bootstrap.css.map'],
  });

  return app.toTree([sourcemaps]);
};
