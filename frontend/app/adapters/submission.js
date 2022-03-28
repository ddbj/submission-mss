import ApplicationAdapter from './application';
import { service } from '@ember/service';

export default class SubmissionAdapter extends ApplicationAdapter {
  @service session;

  queryRecord(store, type, query) {
    if (query.lastSubmitted) {
      return this.ajax('/api/submissions/last_submitted', 'GET', this.headers);
    } else {
      return super.queryRecord(...arguments);
    }
  }
}
