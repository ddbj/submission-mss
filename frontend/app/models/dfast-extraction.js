import { service } from '@ember/service';
import { setOwner } from '@ember/application';

export default class DfastExtraction {
  static async create(owner, ids) {
    const fetchService = owner.lookup('service:fetch');

    const res = await fetchService.request(`/api/dfast_extractions`, {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json'
      },

      body: JSON.stringify({
        ids
      })
    });

    const {_self: url} = await res.json();

    return new DfastExtraction(owner, url);
  }

  @service fetch;

  constructor(owner, url) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback, onError) {
    for (;;) {
      const res     = await this.fetch.request(this.url);
      const payload = await res.json();

      callback(payload);

      switch (payload.state) {
        case 'pending':
          await new Promise(resolve => setTimeout(resolve, 1000));
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
