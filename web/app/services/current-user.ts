import Service, { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import Cookies from 'js-cookie';

import type RequestService from 'mssform/services/request';
import type RouterService from '@ember/routing/router-service';
import type Transition from '@ember/routing/transition';

export default class CurrentUserService extends Service {
  @service declare request: RequestService;
  @service declare router: RouterService;

  @tracked apiKey?: string;
  @tracked uid?: string;

  previousTransition?: Transition;

  get isLoggedIn() {
    return Boolean(this.apiKey);
  }

  ensureLogin(transition: Transition) {
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

    const res = await this.request.fetchWithModal('/me');
    const { uid } = (await res!.json()) as { uid: string };

    this.uid = uid;
  }

  clear() {
    this.apiKey = this.uid = undefined;
  }
}
