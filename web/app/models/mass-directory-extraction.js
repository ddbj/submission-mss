import { service } from '@ember/service';
import { setOwner } from '@ember/application';

import { safeFetchWithModal } from 'mssform/utils/safe-fetch';

export default class MassDirectoryExtraction {
  static async create(owner) {
    const currentUser = owner.lookup('service:current-user');
    const errorModal = owner.lookup('service:error-modal');

    const res = await safeFetchWithModal(
      `/api/mass_directory_extractions`,
      {
        method: 'POST',
        headers: currentUser.authorizationHeader,
      },
      errorModal,
    );

    const { _self: url } = await res.json();

    return new MassDirectoryExtraction(owner, url);
  }

  @service currentUser;
  @service errorModal;

  constructor(owner, url) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback) {
    for (;;) {
      const res = await safeFetchWithModal(
        this.url,
        {
          headers: this.currentUser.authorizationHeader,
        },
        this.errorModal,
      );

      const payload = await res.json();

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
