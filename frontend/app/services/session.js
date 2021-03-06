import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import SimpleAuthSessionService from 'ember-simple-auth/services/session';
import jwtDecode from 'jwt-decode';

export default class SessionService extends SimpleAuthSessionService {
  @service appauth;
  @service router;

  @tracked leavingConfirmationDisabled = false;

  returnTo = null;

  get idTokenPayload() {
    const token = this.data.authenticated.id_token;

    return token ? jwtDecode(token) : null;
  }

  get authorizationHeader() {
    const token = this.data.authenticated.id_token;

    return token ? {Authorization: `Bearer ${token}`} : {};
  }

  async renewToken() {
    await this.authenticate('authenticator:appauth');
  }

  async validateToken() {
    await this.appauth.makeTokenRequestFromRefreshToken(this.data.authenticated.refresh_token);
  }

  handleAuthentication(routeAfterAuthentication) {
    this.router.transitionTo(this.returnTo || routeAfterAuthentication);

    this.returnTo = null;
  }
}
