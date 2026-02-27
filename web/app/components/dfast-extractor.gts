import Component from '@glimmer/component';
import { uniqueId, array } from '@ember/helper';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';
import preventDefault from 'ember-event-helpers/helpers/prevent-default';
import { or } from 'ember-truth-helpers';
import set from 'ember-set-helper/helpers/set';
import pick from '@nullvoxpopuli/ember-composable-helpers/helpers/pick';
import sortBy from '@nullvoxpopuli/ember-composable-helpers/helpers/sort-by';
import mapBy from '@nullvoxpopuli/ember-composable-helpers/helpers/map-by';
import append from '@nullvoxpopuli/ember-composable-helpers/helpers/append';

import DfastExtractorItem from 'mssform/components/dfast-extractor/item';
import filesize from 'mssform/helpers/filesize';
import mapGet from 'mssform/helpers/map-get';
import sum from 'mssform/helpers/sum';
import DfastExtraction from 'mssform/models/dfast-extraction';

import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFile } from 'mssform/models/submission-file';

interface CrossoverError {
  id: string;
}

interface ExtractionPayload {
  id: string;
  files: SubmissionFile[];
}

export interface Signature {
  Args: {
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFile, CrossoverError[]>;
  };
}

export default class DfastExtractorComponent extends Component<Signature> {
  @service declare errorModal: ErrorModalService;

  @tracked jobIdsText = '';
  @tracked extracting = false;
  @tracked files: SubmissionFile[] = [];
  @tracked error: { job_id: string; reason: string } | null = null;

  get jobIds() {
    return this.jobIdsText
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line !== '');
  }

  @action
  async extract() {
    this.extracting = true;
    this.files = [];

    try {
      const extraction = await DfastExtraction.create(getOwner(this)!, this.jobIds);

      await extraction.pollForResult(
        (payload) => {
          this.files = (payload as unknown as ExtractionPayload).files;

          this.args.onPoll(payload as unknown as ExtractionPayload);
        },
        (errorStr: string) => {
          this.errorModal.show(new Error(errorStr));
        },
      );
    } finally {
      this.extracting = false;
    }
  }

  <template>
    <div class="card">
      <form class="card-body" {{on "submit" (preventDefault this.extract)}}>
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
              {{on "input" (pick "target.value" (set this "jobIdsText"))}}
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
          {{#each (sortBy "name" this.files) key="name" as |file|}}
            <DfastExtractorItem
              @file={{file}}
              {{! @glint-expect-error: mapGet returns unknown }}
              @errors={{append file.errors (or (mapGet @crossoverErrors file) (array))}}
            />
          {{/each}}
        </ul>

        <div class="card-footer">
          {{this.files.length}}
          files,
          {{filesize (sum (mapBy "size" this.files))}}
        </div>
      {{/if}}
    </div>
  </template>
}
