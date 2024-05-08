import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class HomeRoute extends Route {
  @service store;
  @service session;

  async model() {
    await this.session.renewToken();

    return await this.store.findAll('submission');
  }
}
