import Component from '@glimmer/component';
import { concat, uniqueId } from '@ember/helper';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';

import ExtractedFiles from 'mssform/components/extracted-files';
import SubmissionFileItem from 'mssform/components/submission-file-item';
import Extraction from 'mssform/models/extraction';
import isRequestError from 'mssform/utils/is-request-error';

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

export default class JobIdExtractorComponent extends Component<Signature> {
  @tracked jobIdsText = '';
  @tracked extracting = false;
  @tracked files: SubmissionFileData[] = [];

  #abort = new AbortController();

  willDestroy() {
    super.willDestroy();
    this.#abort.abort();
  }

  @action handleJobIdsInput(event: Event) {
    this.jobIdsText = (event.target as HTMLTextAreaElement).value;
  }

  get jobIds() {
    return this.jobIdsText
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line !== '');
  }

  @action
  async extract(event: Event) {
    event.preventDefault();
    this.extracting = true;
    this.files = [];

    this.args.onStart();

    try {
      const extraction = await Extraction.create(getOwner(this)!, this.args.endpoint, this.jobIds);

      await extraction.pollForResult((payload) => {
        this.files = payload.files;

        this.args.onPoll(payload);
      }, this.#abort.signal);
    } catch (e) {
      // The error modal has shown what went wrong with the request, and an
      // abort means the submitter has left: nothing is left to handle here.
      if (isRequestError(e) || (e instanceof DOMException && e.name === 'AbortError')) return;

      throw e;
    } finally {
      this.extracting = false;
    }
  }

  <template>
    <div class="card">
      <form class="card-body" {{on "submit" this.extract}}>
        <div class="mb-3">
          {{#let (uniqueId) as |id|}}
            <label for={{id}} class="form-label">{{t (concat @i18nPrefix ".ids-label")}}</label>

            <div class="form-text">{{t (concat @i18nPrefix ".ids-help-html") htmlSafe=true}}</div>

            <textarea
              rows={{6}}
              required
              disabled={{this.extracting}}
              placeholder="01234567-89ab-cdef-0000-000000000001&#10;01234567-89ab-cdef-0000-000000000002"
              class="form-control"
              id={{id}}
              {{on "input" this.handleJobIdsInput}}
            >{{this.jobIdsText}}</textarea>
          {{/let}}
        </div>

        <button type="submit" class="btn btn-primary" disabled={{this.extracting}}>
          {{t (concat @i18nPrefix ".submit")}}
        </button>

        {{#if this.extracting}}
          <div class="spinner-border spinner-border-secondary spinner-border-sm opacity-50 ms-2" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
        {{/if}}
      </form>

      {{#if this.files.length}}
        <ExtractedFiles @files={{this.files}} @crossoverErrors={{@crossoverErrors}}>
          <:default as |file errors|>
            <SubmissionFileItem @file={{file}} @errors={{errors}} />
          </:default>

          <:whereToFix>
            {{t (concat @i18nPrefix ".where-to-fix-html") htmlSafe=true}}
          </:whereToFix>
        </ExtractedFiles>
      {{/if}}
    </div>
  </template>
}
