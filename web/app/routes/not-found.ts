import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type IntlService from 'ember-intl/services/intl';
import type RouterService from '@ember/routing/router-service';

export default class NotFoundRoute extends Route {
  @service declare intl: IntlService;
  @service declare router: RouterService;

  beforeModel() {
    alert(this.intl.t('error.page-not-found'));

    this.router.transitionTo('index');
  }
}
