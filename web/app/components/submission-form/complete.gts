import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';

<template>
  {{t "submission-form.complete.complete-message-html" massId=@model.id htmlSafe=true}}

  <LinkTo @route="home">{{t "go-to-home"}}</LinkTo>
</template>
