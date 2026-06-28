import { service } from '@ember/service';
import { setOwner } from '@ember/owner';

import type { components } from 'schema/openapi';
import type Owner from '@ember/owner';
import type { RequestManager } from '@warp-drive/core';
import type { SubmissionFileData } from 'mssform/models/submission-file';

// The three extraction payloads share the same shape apart from their file
// type; keep _self/id/state/error pinned to the schema and broaden only files.
type ExtractionSchema = components['schemas']['DfastExtraction'];

export type ExtractionError = NonNullable<ExtractionSchema['error']>;
export type ExtractionPayload = Omit<ExtractionSchema, 'files'> & { files: SubmissionFileData[] };

export default class Extraction {
  static async create(owner: Owner, endpoint: string, ids?: string[]) {
    const requestManager = owner.lookup('service:request-manager') as RequestManager;

    const { content } = await requestManager.request<ExtractionPayload>({
      url: endpoint,
      method: 'POST',
      ...(ids ? { data: { ids } } : {}),
    });

    return new Extraction(owner, content._self);
  }

  @service declare requestManager: RequestManager;

  url: string;

  constructor(owner: Owner, url: string) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(
    callback: (payload: ExtractionPayload) => void,
    onError?: (error: ExtractionError) => void,
    signal?: AbortSignal,
  ) {
    for (;;) {
      signal?.throwIfAborted();

      const { content: payload } = await this.requestManager.request<ExtractionPayload>({
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
          onError?.(payload.error!);
          return;
        default:
          throw new Error('must not happen');
      }
    }
  }
}
