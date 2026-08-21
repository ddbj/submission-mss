import { service } from '@ember/service';

import type { NextFn, RequestContext } from '@ember-data/request';
import type CurrentUserService from 'mssform/services/current-user';

const READ_METHODS = ['GET', 'HEAD', 'OPTIONS'];

export default class AuthHandler {
  @service declare currentUser: CurrentUserService;

  async request<T>(context: RequestContext, next: NextFn<T>) {
    const headers = new Headers(context.request.headers);
    const method = context.request.method ?? 'GET';

    // The session is a cookie this never sees; all it has to add is the token
    // that says the write came from us.
    if (!READ_METHODS.includes(method) && this.currentUser.csrfToken) {
      headers.set('X-CSRF-Token', this.currentUser.csrfToken);
    }

    try {
      return await next(Object.assign({}, context.request, { headers, credentials: 'include' as const }));
    } catch (e) {
      if (e && typeof e === 'object' && 'status' in e && e.status === 401 && this.currentUser.isLoggedIn) {
        this.currentUser.forget();
      }

      throw e;
    }
  }
}
