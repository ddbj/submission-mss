import Component from '@glimmer/component';
import { uniqueId } from '@ember/helper';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';

import DfastExtractorItem from 'mssform/components/dfast-extractor/item';
import errorsFor from 'mssform/helpers/errors-for';
import totalFileSize from 'mssform/helpers/total-file-size';
import DfastExtraction from 'mssform/models/dfast-extraction';

import type { components } from 'schema/openapi';
import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

type DfastExtractionPayload = components['schemas']['DfastExtraction'];

export interface Signature {
  Args: {
    onPoll: (payload: DfastExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };
}

export default class DfastExtractorComponent extends Component<Signature> {
  @service declare errorModal: ErrorModalService;

  @tracked jobIdsText = '';
  @tracked extracting = false;
  @tracked files: SubmissionFileData[] = [];
  @tracked error: { job_id: string; reason: string } | null = null;

  #abort = new AbortController();

  willDestroy() {
    super.willDestroy();
    this.#abort.abort();
  }

  get sortedFiles() {
    return this.files.toSorted((a, b) => a.name.localeCompare(b.name));
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
      const extraction = await DfastExtraction.create(getOwner(this)!, this.jobIds);

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
            <label for={{id}} class="form-label">{{t "dfast-extractor.ids-label"}}</label>

            <div class="form-text">{{t "dfast-extractor.ids-help-html" htmlSafe=true}}</div>

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
          {{t "dfast-extractor.submit"}}
        </button>

        {{#if this.extracting}}
          <div class="spinner-border spinner-border-seconcary spinner-border-sm opacity-50 ms-2" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
        {{/if}}

        {{#if this.error}}
          <div class="text-danger mt-2">
            Failed to fetch job (id=<code>{{this.error.job_id}}</code>). reason:
            {{this.error.reason}}
          </div>
        {{/if}}
      </form>

      {{#if this.files.length}}
        <ul class="list-group list-group-flush overflow-auto" style="max-height: 550px">
          {{#each this.sortedFiles key="name" as |file|}}
            <DfastExtractorItem @file={{file}} @errors={{errorsFor file @crossoverErrors}} />
          {{/each}}
        </ul>

        <div class="card-footer">
          {{this.files.length}}
          files,
          {{totalFileSize this.files}}
        </div>
      {{/if}}
    </div>
  </template>
}
