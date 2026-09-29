import Component from '@glimmer/component';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { modifier } from 'ember-modifier';
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
    onStart: () => void;
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };
}

export default class MassDirectoryExtractorComponent extends Component<Signature> {
  @tracked extracting = false;
  @tracked files: SubmissionFileData[] = [];

  // Why the last extraction was turned down. Mostly something the submitter can
  // put right, so it stays beside what they are putting right rather than in
  // the error modal.
  @tracked rejection?: string;

  #abort = new AbortController();

  willDestroy() {
    super.willDestroy();
    this.#abort.abort();
  }

  // The directory is the submitter's own, so there is nothing to ask before
  // looking in it.
  extractOnInsert = modifier(() => {
    void this.extract();
  });

  // Again after the submitter has corrected the files there: they cannot be
  // corrected here.
  @action
  async extract() {
    this.extracting = true;
    this.files = [];
    this.rejection = undefined;

    this.args.onStart();

    try {
      const extraction = await Extraction.create(getOwner(this)!, '/mass_directory_extractions');

      this.rejection = await extraction.pollForResult((payload) => {
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
    <div {{this.extractOnInsert}} class="card">
      <div class="card-body">
        <button type="button" class="btn btn-outline-primary" disabled={{this.extracting}} {{on "click" this.extract}}>
          {{t "mass-directory-extractor.extract-again"}}
        </button>

        {{#if this.extracting}}
          <div class="spinner-border spinner-border-secondary spinner-border-sm opacity-50 ms-2" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
        {{/if}}

        {{#if this.rejection}}
          <div class="alert alert-danger mt-3 mb-0" role="alert">{{this.rejection}}</div>
        {{/if}}
      </div>

      {{#if this.files.length}}
        <ExtractedFiles @files={{this.files}} @crossoverErrors={{@crossoverErrors}}>
          <:default as |file errors|>
            <SubmissionFileItem @file={{file}} @errors={{errors}} />
          </:default>

          <:whereToFix>
            {{t "mass-directory-extractor.where-to-fix"}}
          </:whereToFix>
        </ExtractedFiles>
      {{/if}}
    </div>
  </template>
}
