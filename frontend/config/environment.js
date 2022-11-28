'use strict';

const fs = require('fs');
const path = require('path');

const yaml = require('js-yaml');

module.exports = function (environment) {
  const {
    authorization_endpoint,
    token_endpoint,
    revocation_endpoint,
    userinfo_endpoint,
    end_session_endpoint,
  } = JSON.parse(fs.readFileSync(path.join(__dirname, '../../config/openid-configuration.json')));

  const ENV = {
    modulePrefix: 'mssform',
    environment,
    rootURL: '/',
    locationType: 'history',
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
      },
    },

    APP: {
      enums: yaml.load(fs.readFileSync(path.join(__dirname, '../../config/enums.yml')))
    },

    appauth: {
      clientId: process.env.OPENID_CLIENT_ID,
      redirectPath: '/auth/callback',

      authorizationServiceConfiguration: {
        authorization_endpoint,
        token_endpoint,
        revocation_endpoint,
        userinfo_endpoint,
        end_session_endpoint,
      },
    }
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
