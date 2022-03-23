import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class HomeRoute extends Route {
  @service appauth;
  @service session;

  async beforeModel(transition) {
    const isAuthenticated = await this.session.requireAuthentication(transition, () => {
      this.appauth.makeAuthorizationRequest(transition.intent.url);

      transition.abort();
    });

    if (!isAuthenticated) { return; }

    await this.session.validateToken();
  }
}
