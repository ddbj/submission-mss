import { service } from '@ember/service';
import { setOwner } from '@ember/owner';

import type { components } from 'schema/openapi';
import type Owner from '@ember/owner';
import type RequestService from 'mssform/services/request';

type MassDirectoryExtractionPayload = components['schemas']['MassDirectoryExtraction'];

export default class MassDirectoryExtraction {
  static async create(owner: Owner) {
    const request = owner.lookup('service:request') as RequestService;

    const res = await request.fetchWithModal('/mass_directory_extractions', {
      method: 'POST',
    });

    const { _self: url } = (await res.json()) as MassDirectoryExtractionPayload;

    return new MassDirectoryExtraction(owner, url);
  }

  @service declare request: RequestService;

  url: string;

  constructor(owner: Owner, url: string) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback: (payload: MassDirectoryExtractionPayload) => void) {
    for (;;) {
      const res = await this.request.fetchWithModal(this.url);
      const payload = (await res.json()) as MassDirectoryExtractionPayload;

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
