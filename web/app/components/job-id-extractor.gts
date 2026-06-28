import Component from '@glimmer/component';
import { concat, uniqueId } from '@ember/helper';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';

import ExtractedFiles from 'mssform/components/extracted-files';
import SubmissionFileItem from 'mssform/components/submission-file-item';
import Extraction from 'mssform/models/extraction';

import type { ExtractionPayload } from 'mssform/models/extraction';
import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

export interface Signature {
  Args: {
    endpoint: string;
    i18nPrefix: string;
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };
}

export default class JobIdExtractorComponent extends Component<Signature> {
  @service declare errorModal: ErrorModalService;

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

    try {
      const extraction = await Extraction.create(getOwner(this)!, this.args.endpoint, this.jobIds);

      await extraction.pollForResult(
        (payload) => {
          this.files = payload.files;

          this.args.onPoll(payload);
        },
        (error) => {
          this.errorModal.show(new Error(error.reason ?? error.id));
        },
        this.#abort.signal,
      );
    } catch (e) {
      if (e instanceof DOMException && e.name === 'AbortError') return;
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
        <ExtractedFiles @files={{this.files}} @crossoverErrors={{@crossoverErrors}} as |file errors|>
          <SubmissionFileItem @file={{file}} @errors={{errors}}>
            <:prefix>{{file.jobId}}/</:prefix>
          </SubmissionFileItem>
        </ExtractedFiles>
      {{/if}}
    </div>
  </template>
}
