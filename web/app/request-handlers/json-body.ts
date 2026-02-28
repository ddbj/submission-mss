import type { NextFn } from '@ember-data/request';

export default class JsonBodyHandler {
  request<T>(context: { request: { data?: Record<string, unknown> } }, next: NextFn<T>) {
    const { data } = context.request;

    if (data) {
      const headers = new Headers((context.request as { headers?: HeadersInit }).headers);
      headers.set('Content-Type', 'application/json');

      return next(Object.assign({}, context.request, { data: undefined, headers, body: JSON.stringify(data) }));
    }

    return next(context.request);
  }
}
