import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class HomeIndexController extends Controller {
  @service currentUser;

  @action
  async logout() {
    this.currentUser.logout();

    location.href = '/';
  }
}
