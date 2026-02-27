import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import pageTitle from 'ember-page-title/helpers/page-title';

import RecentSubmissions from 'mssform/components/recent-submissions';

import type { TOC } from '@ember/component/template-only';
import type HomeIndexController from 'mssform/controllers/home/index';

interface Signature {
  Args: {
    controller: HomeIndexController;
  };
}

<template>
  {{pageTitle (t "home.title")}}

  <h1 class="display-6 my-4">{{t "home.title"}}</h1>

  <p>
    {{t "home.login-as-html" account=@controller.currentUser.uid htmlSafe=true}}
    <small>(<button type="button" class="btn btn-link p-0 align-baseline" {{on "click" @controller.logout}}>{{t
          "home.logout"
        }}</button>)</small>
  </p>

  <LinkTo @route="submissions.new" class="btn btn-outline-primary btn-lg">{{t "home.new-submission"}}</LinkTo>

  <h2 class="mt-5">{{t "home.help"}}</h2>

  <ul>
    <li><a href={{t "home.change-email-url"}}>{{t "home.change-email"}}</a></li>
  </ul>

  <h2 class="mt-5">Recent Submissions</h2>

  <RecentSubmissions />
</template> satisfies TOC<Signature>;
