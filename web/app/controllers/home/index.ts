import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';

export default class HomeIndexController extends Controller {
  @service declare currentUser: CurrentUserService;

  @action
  logout() {
    this.currentUser.logout();
  }
}
