import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import preventDefault from 'ember-event-helpers/helpers/prevent-default';
import pageTitle from 'ember-page-title/helpers/page-title';

import RecentSubmissions from 'mssform/components/recent-submissions';

<template>
  {{pageTitle (t "home.title")}}

  <h1 class="display-6 my-4">{{t "home.title"}}</h1>

  <p>
    {{t "home.login-as-html" account=@controller.currentUser.uid htmlSafe=true}}
    <small>(<a {{on "click" (preventDefault @controller.logout)}} href>{{t "home.logout"}}</a>)</small>
  </p>

  <LinkTo @route="submissions.new" class="btn btn-outline-primary btn-lg">{{t "home.new-submission"}}</LinkTo>

  <h2 class="mt-5">{{t "home.help"}}</h2>

  <ul>
    <li><a href={{t "home.change-email-url"}}>{{t "home.change-email"}}</a></li>
  </ul>

  <h2 class="mt-5">Recent Submissions</h2>

  <RecentSubmissions />
</template>
