import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

import Cookies from 'js-cookie';

export default class HomeIndexController extends Controller {
  @service currentUser;

  @action
  async logout() {
    Cookies.remove('api_key');

    location.href = '/';
  }
}
