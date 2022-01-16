import Route from '@ember/routing/route';
import { service } from '@ember/service';

import ENV from 'mssform-web/config/environment';

export default class ApplicationRoute extends Route {
  @service intl;
  @service session;

  async beforeModel() {
    await this.session.setup();

    this.intl.setLocale('en');

    for (const locale of ['en', 'ja']) {
      this.intl.addTranslations(locale, {
        data_types: Object.fromEntries(ENV.APP.enums.data_types.map(({key, label}) => [key, label]))
      })
    }
  }
}
