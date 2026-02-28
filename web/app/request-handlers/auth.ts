import { service } from '@ember/service';

import type { NextFn } from '@ember-data/request';
import type CurrentUserService from 'mssform/services/current-user';

export default class AuthHandler {
  @service declare currentUser: CurrentUserService;

  async request<T>(context: { request: { headers?: HeadersInit } }, next: NextFn<T>) {
    const headers = new Headers(context.request.headers);

    headers.set('Authorization', `Bearer ${this.currentUser.token}`);

    try {
      return await next(Object.assign({}, context.request, { headers }));
    } catch (e) {
      if (e && typeof e === 'object' && 'status' in e && e.status === 401) {
        this.currentUser.logout();
      }

      throw e;
    }
  }
}
