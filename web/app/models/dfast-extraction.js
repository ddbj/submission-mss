import { service } from '@ember/service';
import { setOwner } from '@ember/application';

import { safeFetchWithModal } from 'mssform/utils/safe-fetch';

export default class DfastExtraction {
  static async create(owner, ids) {
    const currentUser = owner.lookup('service:current-user');
    const errorModal = owner.lookup('service:error-modal');

    const res = await safeFetchWithModal(
      `/api/dfast_extractions`,
      {
        method: 'POST',

        headers: {
          ...currentUser.authorizationHeader,
          'Content-Type': 'application/json',
        },

        body: JSON.stringify({
          ids,
        }),
      },
      errorModal,
    );

    const { _self: url } = await res.json();

    return new DfastExtraction(owner, url);
  }

  @service currentUser;
  @service errorModal;

  constructor(owner, url) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback, onError) {
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
