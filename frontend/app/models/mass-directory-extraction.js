import { service } from '@ember/service';
import { setOwner } from '@ember/application';

export default class MassDirectoryExtraction {
  static async create(owner) {
    const fetchService = owner.lookup('service:fetch');

    const res = await fetchService.request(`/api/mass_directory_extractions`, {
      method: 'POST'
    });

    const {_self: url} = await res.json();

    return new MassDirectoryExtraction(owner, url);
  }

  @service fetch;

  constructor(owner, url) {
    setOwner(this, owner);

    this.url = url;
  }

  async pollForResult(callback) {
    for (;;) {
      const res     = await this.fetch.request(this.url);
      const payload = await res.json();

      callback(payload);

      switch (payload.state) {
        case 'pending':
          await new Promise(resolve => setTimeout(resolve, 1000));
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
