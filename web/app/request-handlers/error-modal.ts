import { service } from '@ember/service';

import type { NextFn, RequestContext } from '@ember-data/request';
import type ErrorModalService from 'mssform/services/error-modal';

export default class ErrorModalHandler {
  @service declare errorModal: ErrorModalService;

  async request<T>(context: RequestContext, next: NextFn<T>) {
    try {
      return await next(context.request);
    } catch (e) {
      this.errorModal.show(e as Error);

      throw e;
    }
  }
}
