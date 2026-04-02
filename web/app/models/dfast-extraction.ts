import { service } from '@ember/service';
import { setOwner } from '@ember/owner';

import type { components } from 'schema/openapi';
import type Owner from '@ember/owner';
import type RequestManager from '@ember-data/request';

type DfastExtractionPayload = components['schemas']['DfastExtraction'];

export default class DfastExtraction {
  static async create(owner: Owner, ids: string[]) {
    const requestManager = owner.lookup('service:request-manager') as RequestManager;

    const { content } = await requestManager.request<DfastExtractionPayload>({
      url: '/dfast_extractions',
      method: 'POST',
      data: { ids },
    });

    return new DfastExtraction(owner, content._self);
  }

  @service declare requestManager: RequestManager;

  url: string;

  constructor(owner: Owner, url: string) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(
    callback: (payload: DfastExtractionPayload) => void,
    onError: (error: NonNullable<DfastExtractionPayload['error']>) => void,
    signal?: AbortSignal,
  ) {
    for (;;) {
      signal?.throwIfAborted();

      const { content: payload } = await this.requestManager.request<DfastExtractionPayload>({
        url: this.url,
      });

      signal?.throwIfAborted();

      callback(payload);

      switch (payload.state) {
        case 'pending':
          await new Promise((resolve) => setTimeout(resolve, 1000));
          continue;
        case 'fulfilled':
          return;
        case 'rejected':
          onError(payload.error!);
          return;
        default:
          throw new Error('must not happen');
      }
    }
  }
}
