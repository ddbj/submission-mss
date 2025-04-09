import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';

export default class IndexRoute extends Route {
  @service declare currentUser: CurrentUserService;

  beforeModel() {
    this.currentUser.ensureLogout();
  }
}
