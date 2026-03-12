import Route from '@ember/routing/route';
import { service } from '@ember/service';

import translationsForEn from 'virtual:ember-intl/translations/en';
import translationsForJa from 'virtual:ember-intl/translations/ja';

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
      replace: true,
    },
  };

  async beforeModel(transition: Transition) {
    await this.currentUser.restore();

    const { queryParams } = transition.to!;

    this.intl.addTranslations('en', translationsForEn);
    this.intl.addTranslations('ja', translationsForJa);

    this.intl.addTranslations('en', enumTranslations('en'));
    this.intl.addTranslations('ja', enumTranslations('ja'));

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

interface Enums {
  locales: { key: string; label: Record<'en' | 'ja', string> }[];
  data_types: { key: string; label: string }[];
  sequencers: { key: string; label: string }[];
}

function enumTranslations(locale: 'en' | 'ja') {
  const { locales, data_types, sequencers } = ENV['enums'] as Enums;

  return {
    locales: Object.fromEntries(locales.map(({ key, label }) => [key, label[locale]])),
    data_types: Object.fromEntries(data_types.map(({ key, label }) => [key, label])),
    sequencers: Object.fromEntries(sequencers.map(({ key, label }) => [key, label])),
  };
}
