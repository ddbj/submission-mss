import Helper from '@ember/component/helper';
import { service } from '@ember/service';

import type CurrentUserService from 'mssform/services/current-user';

interface Signature {
  Return: string;
}

export default class UserMassDir extends Helper<Signature> {
  @service declare currentUser: CurrentUserService;

  compute() {
    return `/submission/${this.currentUser.uid}/mass`;
  }
}
