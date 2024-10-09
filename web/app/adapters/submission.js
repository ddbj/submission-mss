import ApplicationAdapter from './application';

export default class SubmissionAdapter extends ApplicationAdapter {
  queryRecord(store, type, query) {
    if (query.lastSubmitted) {
      return this.ajax('/api/submissions/last_submitted', 'GET', this.headers);
    } else {
      return super.queryRecord(...arguments);
    }
  }
}
