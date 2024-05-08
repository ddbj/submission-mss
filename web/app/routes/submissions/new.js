import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SubmissionsNewRoute extends Route {
  @service store;

  model() {
    return this.store.createRecord('submission', {
      contactPerson: this.store.createRecord('contact-person')
    });
  }
}
