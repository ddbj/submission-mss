'use strict';

const EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function(defaults) {
  let app = new EmberApp(defaults, {
    'ember-simple-auth': {
      useSessionSetupMethod: true
    },
  });

  const {Webpack} = require('@embroider/webpack');

  return require('@embroider/compat').compatBuild(app, Webpack, {
    skipBabel: [
      {
        package: 'qunit'
      }
    ],

    packagerOptions: {
      webpackConfig: {
        module: {
          rules: [
            {
              test: /\.s[ac]ss$/i,

              use: [
                'style-loader',
                'css-loader',

                {
                  loader: 'sass-loader',

                  options: {
                    sassOptions: {
                      includePaths: ['./node_modules']
                    }
                  }
                }
              ]
            }
          ]
        }
      }
    }
  });
};
