import ErrorMessage from 'mssform/components/error-message';

import type { TOC } from '@ember/component/template-only';

interface Signature {
  Args: {
    model: Error;
  };
}

<template>
  <h1 class="display-6">Error</h1>

  <ErrorMessage @error={{@model}} />
</template> satisfies TOC<Signature>;
