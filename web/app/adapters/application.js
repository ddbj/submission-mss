import { service } from '@ember/service';

import ActiveModelAdapter from 'active-model-adapter';

import ENV from 'mssform/config/environment';

const url = new URL(ENV.apiURL);

export default class ApplicationAdapter extends ActiveModelAdapter {
  @service currentUser;

  host = url.origin;
  namespace = url.pathname.replace(/^\//, '');

  get headers() {
    return {
      Authorization: `Bearer ${this.currentUser.apiKey}`,
    };
  }
}
