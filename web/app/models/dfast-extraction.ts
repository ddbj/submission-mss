import { service } from '@ember/service';
import { setOwner } from '@ember/application';

import type Owner from '@ember/owner';
import type RequestService from 'mssform/services/request';

export type Payload = {
  state: string;
  files: string[];

  error: {
    job_id: string;
    reason: string;
  };
};

export default class DfastExtraction {
  static async create(owner: Owner, ids: string[]) {
    const request = owner.lookup('service:request') as RequestService;

    const res = await request.fetchWithModal(`/dfast_extractions`, {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        ids,
      }),
    });

    const { _self: url } = (await res.json()) as { _self: string };

    return new DfastExtraction(owner, url);
  }

  @service declare request: RequestService;

  url: string;

  constructor(owner: Owner, url: string) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback: (payload: Payload) => void, onError: (error: Payload['error']) => void) {
    for (;;) {
      const res = await this.request.fetchWithModal(this.url);
      const payload = (await res.json()) as Payload;

      callback(payload);

      switch (payload.state) {
        case 'pending':
          await new Promise((resolve) => setTimeout(resolve, 1000));
          continue;
        case 'fulfilled':
          return;
        case 'rejected':
          onError(payload.error);
          return;
        default:
          throw new Error('must not happen');
      }
    }
  }
}
