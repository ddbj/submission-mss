import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

import 'bootstrap/js/src/dropdown';

export default class ApplicationController extends Controller {
  @service session;

  @action
  async invalidateSession() {
    await this.session.invalidate();
  }
}
