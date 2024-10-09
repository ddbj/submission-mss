import Service, { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import Cookies from 'js-cookie';

import ENV from 'mssform/config/environment';
import { safeFetchWithModal } from 'mssform/utils/safe-fetch';

export default class CurrentUserService extends Service {
  @service errorModal;
  @service router;

  @tracked apiKey;
  @tracked uid;

  get isLoggedIn() {
    return Boolean(this.apiKey);
  }

  get authorizationHeader() {
    return {
      Authorization: `Bearer ${this.apiKey}`,
    };
  }

  ensureLogin(transition) {
    if (this.isLoggedIn) return;

    this.previousTransition = transition;

    this.router.transitionTo('index');
  }

  ensureLogout() {
    if (!this.isLoggedIn) return;

    this.router.transitionTo('home');
  }

  logout() {
    this.clear();
    Cookies.remove('api_key');

    this.router.transitionTo('index');
  }

  async restore() {
    if (this.isLoggedIn) return;

    this.apiKey = Cookies.get('api_key') || undefined;

    if (!this.isLoggedIn) {
      this.clear();
      return;
    }

    const res = await safeFetchWithModal(`${ENV.apiURL}/me`, {
      headers: this.authorizationHeader,
    }, this.errorModal);

    const { uid } = await res.json();

    this.uid = uid;
  }

  clear() {
    this.apiKey = this.uid = undefined;
  }
}
