import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SubmissionRoute extends Route {
  @service session;
  @service store;

  async model({id}) {
    await this.session.renewToken();

    return await this.store.findRecord('submission', id);
  }
}
