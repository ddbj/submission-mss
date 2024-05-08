import Route from '@ember/routing/route';
import { service } from '@ember/service';

import ENV from 'mssform/config/environment';
import { HandledFetchError } from 'mssform/services/fetch';

export default class ApplicationRoute extends Route {
  @service intl;
  @service router;
  @service session;

  queryParams = {
    locale: {refreshModel: true, replace: true}
  };

  async beforeModel(transition) {
    window.addEventListener('error', errorHandler);
    window.addEventListener('unhandledrejection', unhandledRejectionHandler);

    await this.session.setup();

    const {queryParams} = transition.to;

    for (const locale of this.intl.locales) {
      this.intl.addTranslations(locale, enumTranslations(locale));
    }

    const locale = [queryParams.locale, ...navigator.languages].find(l => this.intl.locales.includes(l));

    this.intl.setLocale(locale || 'ja');
  }

  // XXX https://github.com/emberjs/ember.js/issues/18577
  setupController(_controller, _model, transition) {
    const {queryParams, name} = transition.to;

    if (this.intl.primaryLocale !== queryParams.locale) {
      this.router.replaceWith(name, {queryParams: {locale: this.intl.primaryLocale}});
    }
  }
}

function errorHandler(error) {
  if (!(error instanceof HandledFetchError)) {
    alert(`Error: ${error.message}`);
  }

  throw error;
}

function unhandledRejectionHandler(event) {
  const {reason} = event;
  const message = reason instanceof String ? reason : reason.message || JSON.stringify(reason);

  if (!(reason instanceof HandledFetchError)) {
    alert(`Error: ${message}`);
  }

  // PromiseRejectionEvent will be output to console.
}

function enumTranslations(locale) {
  const {enums} = ENV.APP;

  const locales    = Object.fromEntries(enums.locales.map(({key, label}) => [key, label[locale]]));
  const data_types = Object.fromEntries(enums.data_types.map(({key, label}) => [key, label]));
  const sequencers = Object.fromEntries(enums.sequencers.map(({key, label}) => [key, label]));

  return {
    locales,
    data_types,
    sequencers
  };
}
