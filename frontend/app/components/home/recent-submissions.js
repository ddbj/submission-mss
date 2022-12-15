import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class HomeRecentSubmissionsComponent extends Component {
  @service session;
  @service store;

  @action
  async loadSubmissions() {
    await this.session.renewToken();
    await this.store.findAll('submission');
  }

  get submissions() {
    return this.store.peekAll('submission');
  }
}
