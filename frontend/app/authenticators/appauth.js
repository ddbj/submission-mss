import { service } from '@ember/service';

import BaseAuthenticator from 'ember-simple-auth/authenticators/base';

export default class AppAuthAuthenticator extends BaseAuthenticator {
  @service appauth;
  @service session;

  async restore(data) {
    if (data.id_token && data.refresh_token) {
      return data;
    } else {
      throw new Error('id_token and refresh_token are not stored');
    }
  }

  async authenticate() {
    const {isAuthenticated, data} = this.session;

    if (isAuthenticated) {
      const response = await this.appauth.makeTokenRequestFromRefreshToken(data.authenticated.refresh_token);

      return response.toJson();
    } else {
      const {response, returnTo} = await this.appauth.makeTokenRequestFromAuthorizationRequest();

      this.session.returnTo = returnTo;

      return response.toJson();
    }
  }

  async invalidate({refresh_token}) {
    // Chrome raises a "Failed to fetch" error if the response body is empty, but it actually succeeds.
    // https://stackoverflow.com/questions/57477805/why-do-i-get-fetch-failed-loading-when-it-actually-worked
    await this.appauth.makeRevokeTokenRequest(refresh_token, 'refresh_token').catch(err => console.error(err));
  }
}
