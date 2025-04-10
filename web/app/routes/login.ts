import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';

export default class LoginRoute extends Route {
  @service declare currentUser: CurrentUserService;

  async beforeModel() {
    const token = new URL(location.href).searchParams.get('token')!;

    await this.currentUser.login(token);
  }
}
