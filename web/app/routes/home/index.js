import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class HomeRoute extends Route {
  @service store;

  async model() {
    return await this.store.findAll('submission');
  }
}
