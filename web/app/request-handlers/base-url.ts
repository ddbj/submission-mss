import ENV from 'mssform/config/environment';

import type { NextFn } from '@warp-drive/core/request';
import type { RequestContext } from '@warp-drive/core/types/request';

export default class BaseURLHandler {
  request<T>(context: RequestContext, next: NextFn<T>) {
    const { url } = context.request;

    if (url?.startsWith('/')) {
      return next(Object.assign({}, context.request, { url: `${ENV.apiURL}${url}` }));
    }

    return next(context.request);
  }
}
