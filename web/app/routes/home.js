import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class HomeRoute extends Route {
  @service currentUser;
  @service router;

  beforeModel() {
    if (!this.currentUser.isLoggedIn) {
      this.router.transitionTo('index');
    }
  }
}
