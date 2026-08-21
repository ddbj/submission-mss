import Service, { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import type { paths } from 'schema/openapi';
import type { RequestManager } from '@warp-drive/core';
import type RouterService from '@ember/routing/router-service';

type Me = paths['/me']['get']['responses']['200']['content']['application/json'];

export default class CurrentUserService extends Service {
  @service declare requestManager: RequestManager;
  @service declare router: RouterService;

  @tracked uid?: string;

  // Sent back on every request that writes. The session itself is a cookie the
  // browser attaches on its own, and one this never sees.
  csrfToken?: string;

  get isLoggedIn() {
    return Boolean(this.uid);
  }

  // Nothing is remembered of where they were headed: signing in leaves the
  // application entirely and comes back to a fresh one.
  ensureLogin() {
    if (this.isLoggedIn) return;

    this.router.transitionTo('index');
  }

  ensureLogout() {
    if (!this.isLoggedIn) return;

    this.router.transitionTo('home');
  }

  async logout() {
    try {
      await this.requestManager.request({ url: '/session', method: 'DELETE' });

      this.forget();
    } catch {
      // A session the server has already forgotten is the outcome asked for,
      // and answering 401 is how it says so -- which the handler chain has
      // already acted on by the time it reaches here.
    }
  }

  // Asking who is signed in is also how a session that has run out is found:
  // there is nothing here to inspect, only the server's answer.
  async restore() {
    if (this.isLoggedIn) return;

    try {
      const { content } = await this.requestManager.request<Me>({ url: '/me' });

      this.uid = content.uid;
      this.csrfToken = content.csrf_token;
    } catch {
      this.clear();
    }
  }

  // The session ended somewhere other than here -- it ran out, or it was ended
  // elsewhere. Nothing to tell the server; it already knows.
  forget() {
    this.clear();

    this.router.transitionTo('index');
  }

  clear() {
    this.uid = this.csrfToken = undefined;
  }
}
