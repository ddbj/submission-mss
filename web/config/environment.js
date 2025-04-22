'use strict';

const fs = require('fs');
const path = require('path');

const yaml = require('js-yaml');

const railsEnv = process.env.RAILS_ENV || 'development';
const app = yaml.load(fs.readFileSync(path.join(__dirname, '../../config/app.yml')))[railsEnv];
const enums = yaml.load(fs.readFileSync(path.join(__dirname, '../../config/enums.yml')));

module.exports = function (environment) {
  const ENV = {
    modulePrefix: 'mssform',
    environment,
    rootURL: '/',
    locationType: 'history',
    EmberENV: {
      EXTEND_PROTOTYPES: false,
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
      },
    },

    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
    },

    railsEnv,
    apiURL: new URL('/api', app.app_url).href,
    sentryDSN: app.sentry_dsn,
    enums,
  };

  if (environment === 'development') {
    // ENV.APP.LOG_RESOLVER = true;
    // ENV.APP.LOG_ACTIVE_GENERATION = true;
    // ENV.APP.LOG_TRANSITIONS = true;
    // ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
    // ENV.APP.LOG_VIEW_LOOKUPS = true;
  }

  if (environment === 'test') {
    // Testem prefers this...
    ENV.locationType = 'none';

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false;
    ENV.APP.LOG_VIEW_LOOKUPS = false;

    ENV.APP.rootElement = '#ember-testing';
    ENV.APP.autoboot = false;
  }

  if (environment === 'production') {
    // here you can enable a production-specific feature
  }

  return ENV;
};
