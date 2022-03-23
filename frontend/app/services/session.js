import { service } from '@ember/service';

import SimpleAuthSessionService from 'ember-simple-auth/services/session';
import jwtDecode from 'jwt-decode';
import { AppAuthError } from '@openid/appauth';

export default class SessionService extends SimpleAuthSessionService {
  @service appauth;

  get idToken() {
    if (!this.isAuthenticated) { return null; }

    return jwtDecode(this.data.authenticated.id_token);
  }

  get authorizationHeader() {
    if (!this.isAuthenticated) { return {}; }

    return {
      Authorization: `Bearer ${this.data.authenticated.id_token}`
    };
  }

  async renewToken() {
    await this.authenticate('authenticator:appauth');
  }

  async validateToken() {
    try {
      await this.appauth.makeTokenRequestFromRefreshToken(this.data.authenticated.refresh_token);
    } catch (e) {
      // Detect HTTP error
      if (e instanceof AppAuthError && /^\d{3}$/.test(e.message)) {
        console.error(e);
        this.invalidate();
      } else {
        throw e;
      }
    }
  }
}
