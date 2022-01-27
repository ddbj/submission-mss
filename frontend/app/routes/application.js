import Route from '@ember/routing/route';
import { service } from '@ember/service';

import ENV from 'mssform-web/config/environment';

export default class ApplicationRoute extends Route {
  @service intl;
  @service session;

  async beforeModel() {
    await this.session.setup();

    this.intl.setLocale('ja');
  }
}
