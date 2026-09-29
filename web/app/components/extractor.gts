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
    endpoint: string;

    // What to extract from, for an endpoint that asks. Until there is some,
    // there is nothing to extract, and pressing the button only tells
    // onNothingToExtract so.
    ids?: string[];
    onNothingToExtract?: () => void;

    // Extract as soon as shown, where there is nothing to ask first. The
    // button is then for extracting again.
    extractOnInsert?: boolean;

    onStart: () => void;
    onPoll: (payload: ExtractionPayload) => void;
    onEnd: () => void;
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };

  Blocks: {
    // Whatever says what to extract from; disabled while extracting.
    fields?: [extracting: boolean];

    button: [];

    // Where to put right what is wrong with the files extracted.
    whereToFix: [];
  };
}

// Files gathered by the server from somewhere else -- a job, the submitter's
// directory -- for the submitter to look over before sending them. The files
// cannot be changed here; only extracted again once put right where they are.
export default class ExtractorComponent extends Component<Signature> {
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

  extractOnInsert = modifier(() => {
    if (this.args.extractOnInsert) void this.extract();
  });

  @action
  async extract() {
    if (this.args.ids?.length === 0) {
      this.args.onNothingToExtract?.();
      return;
    }

    this.extracting = true;
    this.files = [];
    this.rejection = undefined;

    this.args.onStart();

    try {
      const extraction = await Extraction.create(getOwner(this)!, this.args.endpoint, this.args.ids);

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

      // Not when torn down: whoever took its place may be extracting already.
      if (!this.#abort.signal.aborted) this.args.onEnd();
    }
  }

  <template>
    {{! Not a form of its own: it sits inside the form that sends the files. }}
    <div {{this.extractOnInsert}} class="card">
      <div class="card-body">
        {{yield this.extracting to="fields"}}

        <button
          type="button"
          class="btn {{if @extractOnInsert 'btn-outline-primary' 'btn-primary'}}"
          disabled={{this.extracting}}
          {{on "click" this.extract}}
        >
          {{yield to="button"}}
        </button>

        {{#if this.extracting}}
          <div class="spinner-border spinner-border-secondary spinner-border-sm opacity-50 ms-2" role="status">
            <span class="visually-hidden">{{t "extractor.extracting"}}</span>
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
            {{yield to="whereToFix"}}
          </:whereToFix>
        </ExtractedFiles>
      {{/if}}
    </div>
  </template>
}
