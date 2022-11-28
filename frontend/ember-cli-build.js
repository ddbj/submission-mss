'use strict';

const EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function (defaults) {
  const app = new EmberApp(defaults, {
    sassOptions: {
      includePaths: ['node_modules']
    },

    'ember-simple-auth': {
      useSessionSetupMethod: true
    },

    svgJar: {
      sourceDirs: [
        'node_modules/@primer/octicons/build/svg'
      ]
    }
  });

  return app.toTree();
};
