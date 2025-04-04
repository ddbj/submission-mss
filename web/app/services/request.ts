import Service, { service } from '@ember/service';

import ENV from 'mssform/config/environment';

import type CurrentUserService from 'mssform/services/current-user';
import type ErrorModalService from 'mssform/services/error-modal';

export default class RequestService extends Service {
  @service declare currentUser: CurrentUserService;
  @service declare errorModal: ErrorModalService;

  async fetch(url: string, init?: RequestInit) {
    if (url.startsWith('/')) {
      url = `${ENV.apiURL}${url}`;
    }

    const res = await fetch(url, {
      ...init,

      headers: {
        Authorization: `Bearer ${this.currentUser.apiKey}`,
        ...init?.headers,
      },
    });

    if (!res.ok) throw new FetchError(res);

    return res;
  }

  async fetchWithModal(url: string, init?: RequestInit) {
    try {
      return await this.fetch(url, init);
    } catch (e) {
      this.errorModal.show(e as Error);
    }
  }
}

export class FetchError extends Error {
  response: Response;

  constructor(res: Response) {
    super(res.statusText);

    this.response = res;
  }
}
