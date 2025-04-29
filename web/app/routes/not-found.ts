import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type RouterService from '@ember/routing/router';

export default class NotFoundRoute extends Route {
  @service declare router: RouterService;

  beforeModel() {
    alert('Error: Page not found.');

    this.router.transitionTo('index');
  }
}
