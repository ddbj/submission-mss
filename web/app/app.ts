import Application from '@ember/application';
import Resolver from 'ember-resolver';
import loadInitializers from 'ember-load-initializers';
import config from './config/environment';
import { importSync, isDevelopingApp, isTesting, macroCondition } from '@embroider/macros';

if (macroCondition(isTesting())) {
  // Don't import @sentry/ember in test environment to avoid
  // "Cannot call .lookup('router:main') after the owner has been destroyed" errors
} else {
  const Sentry = importSync('@sentry/ember') as typeof import('@sentry/ember');

  if (config['sentryDSN']) {
    Sentry.init({
      dsn: config['sentryDSN'] as string,
      environment: config['railsEnv'] as string,
      sendDefaultPii: true,
    });
  }
}

if (macroCondition(isDevelopingApp())) {
  importSync('./deprecation-workflow');
}

export default class App extends Application {
  modulePrefix = config.modulePrefix;
  podModulePrefix = config.podModulePrefix;
  Resolver = Resolver.withModules(compatModules);
}

import compatModules from '@embroider/virtual/compat-modules';

loadInitializers(App, config.modulePrefix, compatModules);

import '@primer/octicons/build/build.css';
import 'bootstrap';
import 'bootstrap/dist/css/bootstrap.css';
