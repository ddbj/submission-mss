import Helper from '@ember/component/helper';
import { service } from '@ember/service';

export default class UserMassDir extends Helper {
  @service currentUser;

  compute() {
    return `/submission/${this.currentUser.uid}/mass`;
  }
}
