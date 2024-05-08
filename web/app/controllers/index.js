import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class IndexController extends Controller {
  @service appauth;
  @service router;

  @action
  authenticate() {
    this.appauth.makeAuthorizationRequest(this.router.currentURL);
  }
}
