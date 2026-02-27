import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import { formatTime } from 'ember-intl';
import sortBy from '@nullvoxpopuli/ember-composable-helpers/helpers/sort-by';

import type { TOC } from '@ember/component/template-only';

interface Upload {
  id: string;
  created_at: string;
  files: string[];
}

interface Signature {
  Args: {
    model: {
      id: string;
      uploads: Upload[];
    };
  };
}

<template>
  <h1 class="display-6 my-4">{{@model.id}}</h1>

  <LinkTo @route="submission.upload" @model={{@model}} class="btn btn-outline-primary">
    {{t "submission.show.re-upload"}}
  </LinkTo>

  <h2 class="mt-4">{{t "submission.show.submission-files"}}</h2>

  <div class="vstack gap-3">
    {{#each (sortBy "id" @model.uploads) as |upload|}}
      <div class="card">
        <div class="card-header">
          {{formatTime
            upload.created_at
            year="numeric"
            month="long"
            day="numeric"
            hour="numeric"
            minute="numeric"
            timeZoneName="short"
          }}
        </div>

        <ul class="list-group list-group-flush">
          {{#each upload.files as |file|}}
            <li class="list-group-item">{{file}}</li>
          {{/each}}
        </ul>
      </div>
    {{/each}}
  </div>
</template> satisfies TOC<Signature>;
