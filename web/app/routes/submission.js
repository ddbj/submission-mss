import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SubmissionRoute extends Route {
  @service store;

  async model({ id }) {
    return await this.store.findRecord('submission', id);
  }
}
