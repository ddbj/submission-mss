import { service } from '@ember/service';
import { setOwner } from '@ember/owner';

import type { components } from 'schema/openapi';
import type Owner from '@ember/owner';
import type { RequestManager } from '@warp-drive/core';

type MassDirectoryExtractionPayload = components['schemas']['MassDirectoryExtraction'];

export default class MassDirectoryExtraction {
  static async create(owner: Owner) {
    const requestManager = owner.lookup('service:request-manager') as RequestManager;

    const { content } = await requestManager.request<MassDirectoryExtractionPayload>({
      url: '/mass_directory_extractions',
      method: 'POST',
    });

    return new MassDirectoryExtraction(owner, content._self);
  }

  @service declare requestManager: RequestManager;

  url: string;

  constructor(owner: Owner, url: string) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback: (payload: MassDirectoryExtractionPayload) => void, signal?: AbortSignal) {
    for (;;) {
      signal?.throwIfAborted();

      const { content: payload } = await this.requestManager.request<MassDirectoryExtractionPayload>({
        url: this.url,
      });

      signal?.throwIfAborted();

      callback(payload);

      switch (payload.state) {
        case 'pending':
          await new Promise((resolve) => setTimeout(resolve, 1000));
          continue;
        case 'fulfilled':
        case 'rejected':
          return;
        default:
          throw new Error('must not happen');
      }
    }
  }
}
