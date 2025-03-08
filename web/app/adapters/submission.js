import ApplicationAdapter from './application';

import ENV from 'mssform/config/environment';

export default class SubmissionAdapter extends ApplicationAdapter {
  queryRecord(store, type, query) {
    if (query.lastSubmitted) {
      return this.ajax(`${ENV.apiURL}/submissions/last_submitted`, 'GET', this.headers);
    } else {
      return super.queryRecord(...arguments);
    }
  }
}
