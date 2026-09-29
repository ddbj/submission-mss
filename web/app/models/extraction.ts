import { service } from '@ember/service';
import { setOwner } from '@ember/owner';

import type { components } from 'schema/openapi';
import type Owner from '@ember/owner';
import type IntlService from 'ember-intl/services/intl';
import type { RequestManager } from '@warp-drive/core';
import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFileData } from 'mssform/models/submission-file';

// The three extraction payloads share the same shape apart from their file
// type; keep _self/id/state/error pinned to the schema and broaden only files.
type ExtractionSchema = components['schemas']['DfastExtraction'];

export type ExtractionError = components['schemas']['ExtractionError'];
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

  @service declare errorModal: ErrorModalService;
  @service declare intl: IntlService;
  @service declare requestManager: RequestManager;

  url: string;

  constructor(owner: Owner, url: string) {
    setOwner(this, owner);

    this.url = url;
  }

  // Reports the files found so far until the extraction is done with. One that
  // is turned down is explained in the error modal.
  async pollForResult(callback: (payload: ExtractionPayload) => void, signal?: AbortSignal) {
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
          this.errorModal.show(new Error(this.describe(payload.error!)));
          return;
        default:
          throw new Error('must not happen');
      }
    }
  }

  describe({ id, job_id, other_job_id, file, detail }: ExtractionError) {
    return this.intl.t(`extraction-error.${id}`, { jobId: job_id, otherJobId: other_job_id, file, detail });
  }
}
