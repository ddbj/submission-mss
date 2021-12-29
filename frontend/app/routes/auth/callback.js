import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default class AuthCallbackRoute extends Route {
  @service router;
  @service session;

  async beforeModel() {
    await this.session.authenticate('authenticator:appauth', {
      complete:    true,
      redirectUri: new URL('/auth/callback', location)
    });

    this.router.transitionTo('index');
  }
}
