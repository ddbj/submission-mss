import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default class AuthIndexRoute extends Route {
  @service session;
  @service router;

  async beforeModel() {
    await this.session.authenticate('authenticator:appauth', {
      redirectUri: new URL('/auth/callback', location)
    });
  }
}
