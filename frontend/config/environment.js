'use strict';

const fs = require('fs');
const path = require('path');

module.exports = function (environment) {
  const {
    authorization_endpoint,
    token_endpoint,
    revocation_endpoint,
    userinfo_endpoint,
    end_session_endpoint,
  } = JSON.parse(
    fs.readFileSync(process.env.OPENID_CONFIGURATION_PATH)
  );

  let ENV = {
    modulePrefix: 'mssform-web',
    environment,
    rootURL: '/',
    locationType: 'auto',
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
      },
      EXTEND_PROTOTYPES: {
        // Prevent Ember Data from overriding Date.parse.
        Date: false,
      },
    },

    APP: {
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
