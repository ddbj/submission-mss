import Helper from '@ember/component/helper';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';

export default class UserMassDir extends Helper {
  @service declare currentUser: CurrentUserService;

  compute() {
    return `/submission/${this.currentUser.uid}/mass`;
  }
}
