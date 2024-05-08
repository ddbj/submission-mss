import Service from '@ember/service';
import { service } from '@ember/service';

import { handleAppAuthHTTPError, handleFetchError } from 'mssform/utils/error-handler';

export class HandledFetchError extends Error {
}

export default class FetchService extends Service {
  @service session;

  async request(url, opts = {}) {
    try {
      await this.session.renewToken();
    } catch (e) {
      handleAppAuthHTTPError(e, this.session);

      throw new HandledFetchError();
    }

    const res = await fetch(url, {
      ...opts,

      headers: {
        Authorization: `Bearer ${this.session.idToken}`,

        ...(opts.headers || {})
      }
    });

    if (!res.ok) {
      handleFetchError(res, this.session);

      throw new HandledFetchError();
    }

    return res;
  }
}
