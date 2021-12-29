import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AuthCallbackRoute extends Route {
  @service router;
  @service session;

  async beforeModel() {
    await this.session.authenticate('authenticator:appauth');

    this.router.transitionTo('index');
  }
}
