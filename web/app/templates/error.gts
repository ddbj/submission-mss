import { t } from 'ember-intl';

import ErrorMessage from 'mssform/components/error-message';

import type { TOC } from '@ember/component/template-only';

interface Signature {
  Args: {
    model: Error;
  };
}

<template>
  <h1 class="display-6">{{t "error.title"}}</h1>

  <ErrorMessage @error={{@model}} />
</template> satisfies TOC<Signature>;
