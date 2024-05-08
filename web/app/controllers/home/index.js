import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class HomeIndexController extends Controller {
  @service session;

  @action
  async logout() {
    await this.session.invalidate();
  }
}
