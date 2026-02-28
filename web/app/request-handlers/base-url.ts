import ENV from 'mssform/config/environment';

import type { NextFn } from '@ember-data/request';

export default class BaseURLHandler {
  request<T>(context: { request: { url?: string } }, next: NextFn<T>) {
    const { url } = context.request;

    if (url?.startsWith('/')) {
      return next(Object.assign({}, context.request, { url: `${ENV.apiURL}${url}` }));
    }

    return next(context.request);
  }
}
