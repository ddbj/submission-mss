import Route from '@ember/routing/route';
import { service } from '@ember/service';

import { handleAppAuthHTTPError, handleFetchError } from 'mssform/utils/error-handler';

export default class SubmissionRoute extends Route {
  @service session;

  async model({id}, transition) {
    try {
      await this.session.renewToken();
    } catch (e) {
      transition.abort();
      handleAppAuthHTTPError(e, this.session);
      return;
    }

    const res = await fetch(`/api/submissions/${id}`, {
      method:  'HEAD',
      headers: this.session.authorizationHeader
    });

    if (!res.ok) {
      transition.abort();
      handleFetchError(res, this.session);
      return;
    }

    return {id};
  }
}
