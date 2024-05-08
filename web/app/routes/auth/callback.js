import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AuthCallbackRoute extends Route {
  @service session;

  async beforeModel() {
    await this.session.authenticate('authenticator:appauth');
  }
}
