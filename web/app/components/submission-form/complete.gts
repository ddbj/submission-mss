import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';

import type { TOC } from '@ember/component/template-only';
import type Submission from 'mssform/models/submission';

interface Signature {
  Args: {
    model: Submission;
  };
}

<template>
  {{t "submission-form.complete.complete-message-html" massId=@model.id htmlSafe=true}}

  <LinkTo @route="home">{{t "go-to-home"}}</LinkTo>
</template> satisfies TOC<Signature>;
