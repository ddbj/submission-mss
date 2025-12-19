import Route from '@ember/routing/route';
import { service } from '@ember/service';

import translationsForEn from 'virtual:ember-intl/translations/en';
import translationsForJa from 'virtual:ember-intl/translations/ja';

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

    this.intl.addTranslations('en', translationsForEn);
    this.intl.addTranslations('ja', translationsForJa);

    this.intl.addTranslations('en', enumTranslations('en'));
    this.intl.addTranslations('ja', enumTranslations('ja'));

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
  const { enums } = ENV;

  const locales = Object.fromEntries(enums.locales.map(({ key, label }) => [key, label[locale]]));
  const data_types = Object.fromEntries(enums.data_types.map(({ key, label }) => [key, label]));
  const sequencers = Object.fromEntries(enums.sequencers.map(({ key, label }) => [key, label]));

  return {
    locales,
    data_types,
    sequencers,
  };
}
