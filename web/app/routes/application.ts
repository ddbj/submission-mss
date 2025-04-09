import Route from '@ember/routing/route';
import { service } from '@ember/service';

import ENV from 'mssform/config/environment';

import type CurrentUserService from 'mssform/services/current-user';
import type IntlService from 'ember-intl/services/intl';
import type RouterService from '@ember/routing/router-service';
import type Transition from '@ember/routing/transition';

export default class ApplicationRoute extends Route {
  @service declare currentUser: CurrentUserService;
  @service declare intl: IntlService;
  @service declare router: RouterService;

  queryParams = {
    locale: {
      refreshModel: true,
      replace: true,
    },
  };

  async beforeModel(transition: Transition) {
    await this.currentUser.restore();

    const { queryParams } = transition.to!;

    for (const locale of this.intl.locales) {
      this.intl.addTranslations(locale, enumTranslations(locale));
    }

    const locale = [queryParams['locale'] as string, ...navigator.languages].find((l) => this.intl.locales.includes(l));

    this.intl.setLocale(locale || 'ja');
  }

  // XXX https://github.com/emberjs/ember.js/issues/18577
  setupController(_controller: unknown, _model: unknown, transition: Transition) {
    const { queryParams, name } = transition.to!;

    if (this.intl.primaryLocale !== queryParams['locale']) {
      this.router.replaceWith(name, {
        queryParams: { locale: this.intl.primaryLocale },
      });
    }
  }
}

function enumTranslations(locale: string) {
  const { enums } = ENV;

  const locales = Object.fromEntries(enums.locales.map(({ key, label }) => [key, label[locale]]));
  const data_types = Object.fromEntries(enums.data_types.map(({ key, label }) => [key, label]));
  const sequencers = Object.fromEntries(enums.sequencers.map(({ key, label }) => [key, label]));

  return {
    locales,
    data_types,
    sequencers,
  };
}
