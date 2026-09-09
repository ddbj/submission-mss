import type { NextFn } from '@warp-drive/core/request';
import type { RequestContext } from '@warp-drive/core/types/request';

export default class JsonBodyHandler {
  request<T>(context: RequestContext, next: NextFn<T>) {
    const { data } = context.request;

    if (data) {
      const headers = new Headers(context.request.headers);
      headers.set('Content-Type', 'application/json');

      return next(Object.assign({}, context.request, { data: undefined, headers, body: JSON.stringify(data) }));
    }

    return next(context.request);
  }
}
