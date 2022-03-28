import Route from '@ember/routing/route';
import { service } from '@ember/service';

import { handleAppAuthHTTPError } from 'mssform/utils/error-handler';

export default class HomeRoute extends Route {
  @service appauth;
  @service session;

  async beforeModel(transition) {
    const hasToken = await this.session.requireAuthentication(transition, () => {
      this.appauth.makeAuthorizationRequest(transition.intent.url);

      transition.abort();
    });

    if (hasToken) {
      try {
        await this.session.validateToken();
      } catch (e) {
        handleAppAuthHTTPError(e, this.session);
        return;
      }
    }
  }
}
