import Route from '@ember/routing/route';
import { service } from '@ember/service';

import ENV from 'mssform/config/environment';

export default class ApplicationRoute extends Route {
  @service intl;
  @service session;

  async beforeModel() {
    await this.session.setup();

    for (const locale of ['en', 'ja']) {
      this.intl.addTranslations(locale, enumTranslations(locale));
    }

    this.intl.setLocale('ja');
  }
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
