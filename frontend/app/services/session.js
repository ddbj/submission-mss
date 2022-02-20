import SimpleAuthSessionService from 'ember-simple-auth/services/session';
import jwtDecode from 'jwt-decode';

export default class SessionService extends SimpleAuthSessionService {
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
}
