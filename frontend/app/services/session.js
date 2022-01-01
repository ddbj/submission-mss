import SimpleAuthSessionService from 'ember-simple-auth/services/session';
import jwtDecode from 'jwt-decode';

export default class SessionService extends SimpleAuthSessionService {
  get idToken() {
    if (!this.isAuthenticated) {
      return null;
    }

    const {id_token} = this.data.authenticated;

    return jwtDecode(id_token);
  }
}
