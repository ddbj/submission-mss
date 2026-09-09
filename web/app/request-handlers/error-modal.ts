import { service } from '@ember/service';

import type { NextFn } from '@warp-drive/core/request';
import type { RequestContext } from '@warp-drive/core/types/request';
import type ErrorModalService from 'mssform/services/error-modal';

export default class ErrorModalHandler {
  @service declare errorModal: ErrorModalService;

  async request<T>(context: RequestContext, next: NextFn<T>) {
    try {
      return await next(context.request);
    } catch (e) {
      // Nobody being signed in is not something to put in front of the visitor:
      // the application answers it by showing them the way in.
      if (!isUnauthorized(e) && !context.request.options?.['suppressErrorModal']) {
        this.errorModal.show(e as Error);
      }

      throw e;
    }
  }
}

function isUnauthorized(error: unknown) {
  return typeof error === 'object' && error !== null && 'status' in error && error.status === 401;
}
