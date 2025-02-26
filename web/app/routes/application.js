import Route from '@ember/routing/route';
import { service } from '@ember/service';

import ENV from 'mssform/config/environment';

export default class ApplicationRoute extends Route {
  @service currentUser;
  @service intl;
  @service router;

  queryParams = {
    locale: {
      refreshModel: true,
      replace: true,
    },
  };

  async beforeModel(transition) {
    await this.currentUser.restore();

    const { queryParams } = transition.to;

    for (const locale of this.intl.locales) {
      this.intl.addTranslations(locale, enumTranslations(locale));
    }

    const locale = [queryParams.locale, ...navigator.languages].find((l) => this.intl.locales.includes(l));

    this.intl.setLocale(locale || 'ja');
  }

  // XXX https://github.com/emberjs/ember.js/issues/18577
  setupController(_controller, _model, transition) {
    const { queryParams, name } = transition.to;

    if (this.intl.primaryLocale !== queryParams.locale) {
      this.router.replaceWith(name, {
        queryParams: { locale: this.intl.primaryLocale },
      });
    }
  }
}

function enumTranslations(locale) {
  const { enums } = ENV.APP;

  const locales = Object.fromEntries(enums.locales.map(({ key, label }) => [key, label[locale]]));
  const data_types = Object.fromEntries(enums.data_types.map(({ key, label }) => [key, label]));
  const sequencers = Object.fromEntries(enums.sequencers.map(({ key, label }) => [key, label]));

  return {
    locales,
    data_types,
    sequencers,
  };
}
