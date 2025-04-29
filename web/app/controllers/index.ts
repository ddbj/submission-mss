import Controller from '@ember/controller';

import ENV from 'mssform/config/environment';

export default class IndexController extends Controller {
  authURL = new URL('/auth/keycloak', ENV.apiURL).href;
}
