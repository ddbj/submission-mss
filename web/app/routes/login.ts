import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';
import type RouterService from '@ember/routing/router-service';

export default class LoginRoute extends Route {
  @service declare currentUser: CurrentUserService;
  @service declare router: RouterService;

  async beforeModel() {
    const token = new URL(location.href).searchParams.get('token');

    if (token) {
      await this.currentUser.login(token);
    }

    this.router.transitionTo('index');
  }
}
