import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import 'bootstrap/js/src/dropdown';

export default class ApplicationController extends Controller {
  @service session;

  @tracked locale;

  queryParams = ['locale'];

  @action
  async invalidateSession() {
    await this.session.invalidate();
  }

  @action
  changeLocale(locale) {
    this.locale = locale;
  }
}
