import Component from '@glimmer/component';
import { concat, uniqueId } from '@ember/helper';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
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

  // The button was pressed with no IDs in the field. Rather than a button that
  // cannot be pressed and does not say why, it can be, and then the field does.
  @tracked askedWithoutIds = false;

  #textarea?: HTMLTextAreaElement;

  registerTextarea = modifier((element: HTMLTextAreaElement) => {
    this.#textarea = element;
  });

  @action handleJobIdsInput(event: Event) {
    this.jobIdsText = (event.target as HTMLTextAreaElement).value;
  }

  get jobIds() {
    return this.jobIdsText
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line !== '');
  }

  // Gone as soon as there is an ID in the field.
  get isMissing() {
    return this.askedWithoutIds && this.jobIds.length === 0;
  }

  // To the field, which then reads out what it lacks -- again on every press,
  // where an alert already on the page would say nothing more.
  @action askForIds() {
    this.askedWithoutIds = true;
    this.#textarea?.focus();
  }

  // What was missing last time has been put right, whatever the field is
  // edited into from here.
  @action start() {
    this.askedWithoutIds = false;
    this.args.onStart();
  }

  <template>
    <Extractor
      @endpoint={{@endpoint}}
      @ids={{this.jobIds}}
      @onNothingToExtract={{this.askForIds}}
      @onStart={{this.start}}
      @onPoll={{@onPoll}}
      @crossoverErrors={{@crossoverErrors}}
    >
      <:fields as |extracting|>
        <div class="mb-3">
          {{#let (uniqueId) (uniqueId) as |id feedbackId|}}
            <label for={{id}} class="form-label">{{t (concat @i18nPrefix ".ids-label")}}</label>

            <div class="form-text">{{t (concat @i18nPrefix ".ids-help-html") htmlSafe=true}}</div>

            <textarea
              rows={{6}}
              disabled={{extracting}}
              placeholder="01234567-89ab-cdef-0000-000000000001&#10;01234567-89ab-cdef-0000-000000000002"
              class="form-control {{if this.isMissing 'is-invalid'}}"
              aria-invalid={{if this.isMissing "true"}}
              aria-describedby={{if this.isMissing feedbackId}}
              id={{id}}
              {{this.registerTextarea}}
              {{on "input" this.handleJobIdsInput}}
            >{{this.jobIdsText}}</textarea>

            {{#if this.isMissing}}
              <div id={{feedbackId}} class="invalid-feedback">{{t (concat @i18nPrefix ".ids-missing")}}</div>
            {{/if}}
          {{/let}}
        </div>
      </:fields>

      <:button>{{t (concat @i18nPrefix ".extract")}}</:button>

      <:whereToFix>{{t (concat @i18nPrefix ".where-to-fix-html") htmlSafe=true}}</:whereToFix>
    </Extractor>
  </template>
}
