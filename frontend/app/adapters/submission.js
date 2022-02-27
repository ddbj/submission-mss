import ApplicationAdapter from './application';
import { service } from '@ember/service';

export default class SubmissionAdapter extends ApplicationAdapter {
  @service session;

  async queryRecord(store, type, query) {
    if (query.lastSubmitted) {
      await this.session.renewToken();

      return this.ajax('/api/submissions/last_submitted', 'GET', {
        headers: this.session.authorizationHeader
      });
    } else {
      return super.queryRecord(...arguments);
    }
  }
}
