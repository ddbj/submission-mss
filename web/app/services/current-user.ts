import Service, { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import type RequestService from 'mssform/services/request';
import type RouterService from '@ember/routing/router-service';
import type Transition from '@ember/routing/transition';

export default class CurrentUserService extends Service {
  @service declare request: RequestService;
  @service declare router: RouterService;

  @tracked token?: string;
  @tracked uid?: string;

  previousTransition?: Transition;

  get isLoggedIn() {
    return Boolean(this.token);
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

  async login(token: string) {
    this.clear();
    localStorage.setItem('token', token);

    await this.restore();

    if (this.previousTransition) {
      this.previousTransition.retry();
      this.previousTransition = undefined;
    } else {
      this.router.transitionTo('index');
    }
  }

  logout() {
    this.clear();
    localStorage.removeItem('token');

    this.router.transitionTo('index');
  }

  async restore() {
    if (this.isLoggedIn) return;

    this.token = localStorage.getItem('token') || undefined;

    if (!this.isLoggedIn) {
      this.clear();
      return;
    }

    const res = await this.request.fetchWithModal('/me');
    const { uid } = (await res.json()) as { uid: string };

    this.uid = uid;
  }

  clear() {
    this.token = this.uid = undefined;
  }
}
