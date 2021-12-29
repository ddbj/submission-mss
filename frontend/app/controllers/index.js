import Controller from '@ember/controller';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

import jwtDecode from 'jwt-decode';

export default class IndexController extends Controller {
  @service appauth;
  @service session;

  @action
  authenticate() {
    this.appauth.makeAuthorizationRequest();
  }

  @action
  async invalidateSession() {
    await this.session.invalidate();
  }

  get idToken() {
    const {id_token} = this.session.data.authenticated;

    if (!id_token) { return null; }

    return jwtDecode(id_token);
  }
}
