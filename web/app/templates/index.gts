import { t } from 'ember-intl';

<template>
  <h1 class="display-6 my-4">{{t "index.title"}}</h1>

  {{t "index.instructions-html" htmlSafe=true}}

  <form action={{@controller.authURL}} method="POST">
    <button type="submit" class="btn btn-primary btn-lg">{{t "index.login"}}</button>
  </form>

  <ul class="list-unstyled mt-3">
    <li>{{t "index.reset-password-html" htmlSafe=true}}</li>
    <li>{{t "index.create-account-html" htmlSafe=true}}</li>
  </ul>
</template>
