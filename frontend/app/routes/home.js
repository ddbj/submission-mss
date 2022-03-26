import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class HomeRoute extends Route {
  @service appauth;
  @service session;

  async beforeModel(transition) {
    const hasToken = await this.session.requireAuthentication(transition, () => {
      this.appauth.makeAuthorizationRequest(transition.intent.url);

      transition.abort();
    });

    if (hasToken && !(await this.session.renewToken())) {
      this.session.invalidate();
    }
  }
}
