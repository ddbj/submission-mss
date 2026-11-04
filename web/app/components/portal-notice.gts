import { t } from 'ember-intl';

import type { TOC } from '@ember/component/template-only';

interface Signature {
  Args: {
    // Where the portal keeps the submission; null when none is configured.
    url: string | null;
  };
}

// A submission the GGS submission portal made takes its further files there:
// the portal keeps its versions, and turns files sent here away.
<template>
  <div class="alert alert-info" role="status">
    <p class="mb-0">{{t "portal-notice.text"}}</p>

    {{#if @url}}
      <a href={{@url}} class="btn btn-primary mt-3">{{t "portal-notice.open"}}</a>
    {{/if}}
  </div>
</template> satisfies TOC<Signature>;
