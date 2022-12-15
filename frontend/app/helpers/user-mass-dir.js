import Helper from '@ember/component/helper';
import { service } from '@ember/service';

export default class UserMassDir extends Helper {
  @service session;

  compute() {
    const {idTokenPayload} = this.session;

    if (!idTokenPayload) { return null; }

    const {preferred_username} = idTokenPayload;

    return `/submission/${preferred_username}/mass`;
  }
}
