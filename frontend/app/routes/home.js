import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class HomeRoute extends Route {
  @service appauth;
  @service session;

  beforeModel(transition) {
    this.session.requireAuthentication(transition, () => {
      this.appauth.makeAuthorizationRequest(transition.intent.url);

      transition.abort();
    });
  }
}