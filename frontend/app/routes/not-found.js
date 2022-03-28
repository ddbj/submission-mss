import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class NotFoundRoute extends Route {
  @service router;

  beforeModel() {
    alert('Error: Page not found.');

    this.router.transitionTo('index');
  }
}
