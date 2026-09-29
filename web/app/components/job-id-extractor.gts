import Component from '@glimmer/component';
import { concat, uniqueId } from '@ember/helper';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';

import Extractor from 'mssform/components/extractor';

import type { ExtractionPayload } from 'mssform/models/extraction';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

export interface Signature {
  Args: {
    endpoint: string;
    i18nPrefix: string;
    onStart: () => void;
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };
}

// Files extracted from the jobs the submitter names, one ID to a line.
export default class JobIdExtractorComponent extends Component<Signature> {
  @tracked jobIdsText = '';

  @action handleJobIdsInput(event: Event) {
    this.jobIdsText = (event.target as HTMLTextAreaElement).value;
  }

  get jobIds() {
    return this.jobIdsText
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line !== '');
  }

  <template>
    <Extractor
      @endpoint={{@endpoint}}
      @ids={{this.jobIds}}
      @onStart={{@onStart}}
      @onPoll={{@onPoll}}
      @crossoverErrors={{@crossoverErrors}}
    >
      <:fields as |extracting|>
        <div class="mb-3">
          {{#let (uniqueId) as |id|}}
            <label for={{id}} class="form-label">{{t (concat @i18nPrefix ".ids-label")}}</label>

            <div class="form-text">{{t (concat @i18nPrefix ".ids-help-html") htmlSafe=true}}</div>

            <textarea
              rows={{6}}
              disabled={{extracting}}
              placeholder="01234567-89ab-cdef-0000-000000000001&#10;01234567-89ab-cdef-0000-000000000002"
              class="form-control"
              id={{id}}
              {{on "input" this.handleJobIdsInput}}
            >{{this.jobIdsText}}</textarea>
          {{/let}}
        </div>
      </:fields>

      <:button>{{t (concat @i18nPrefix ".extract")}}</:button>

      <:whereToFix>{{t (concat @i18nPrefix ".where-to-fix-html") htmlSafe=true}}</:whereToFix>
    </Extractor>
  </template>
}
