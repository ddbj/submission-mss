import Application from '@ember/application';
import Resolver from 'ember-resolver';
import loadInitializers from 'ember-load-initializers';
import config from 'mssform/config/environment';
import { importSync, isDevelopingApp, macroCondition } from '@embroider/macros';

import * as Sentry from '@sentry/ember';

if (config.sentryDSN) {
  Sentry.init({
    dsn: config.sentryDSN,
    environment: config.railsEnv,
    sendDefaultPii: true,
  });
}

if (macroCondition(isDevelopingApp())) {
  importSync('./deprecation-workflow');
}

export default class App extends Application {
  modulePrefix = config.modulePrefix;
  podModulePrefix = config.podModulePrefix;
  Resolver = Resolver;
}

loadInitializers(App, config.modulePrefix);

import '@primer/octicons/build/build.css';
import 'bootstrap';
import 'bootstrap/dist/css/bootstrap.css';
