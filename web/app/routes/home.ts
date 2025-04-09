import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';
import type RouterService from '@ember/routing/router';

export default class HomeRoute extends Route {
  @service declare currentUser: CurrentUserService;
  @service declare router: RouterService;

  beforeModel() {
    if (!this.currentUser.isLoggedIn) {
      this.router.transitionTo('index');
    }
  }
}
