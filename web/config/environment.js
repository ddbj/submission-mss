'use strict';

const fs = require('fs');
const path = require('path');

const yaml = require('js-yaml');
const enums = yaml.load(fs.readFileSync(path.join(__dirname, '../../config/enums.yml')));

module.exports = function (environment) {
  // Origin of the Rails backend, used as the base for every backend URL below.
  //
  // In production the built assets are served from the same origin as the API,
  // so we leave this empty and let the URLs resolve relative to wherever the app
  // is served. That keeps a single production image environment-agnostic (no
  // per-environment APP_URL baked in at build time).
  //
  // In development the Ember and Rails servers run on separate origins, so we
  // honour APP_URL and fall back to the default Puma port.
  const appURL =
    environment === 'development'
      ? process.env.APP_URL || 'http://localhost:3000'
      : environment === 'test'
        ? 'http://localhost:3000'
        : '';

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

    appURL,
    enums,
  };

  ENV.apiURL = `${appURL}/api`;
  ENV.authURL = `${appURL}/auth/keycloak`;
  ENV.directUploadURL = `${appURL}/api/direct_uploads`;

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
