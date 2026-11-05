import PortalNotice from 'mssform/components/portal-notice';
import UploadForm from 'mssform/components/upload-form';

import type { TOC } from '@ember/component/template-only';
import type { components } from 'schema/openapi';
import type Submission from 'mssform/models/submission';

interface Signature {
  Args: {
    model: Submission & Pick<components['schemas']['Submission'], 'portal_managed' | 'portal_url'>;
  };
}

<template>
  {{#if @model.portal_managed}}
    <PortalNotice @url={{@model.portal_url}} />
  {{else}}
    <UploadForm @model={{@model}} />
  {{/if}}
</template> satisfies TOC<Signature>;
