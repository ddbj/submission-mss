import Component from '@glimmer/component';
import { fn, concat } from '@ember/helper';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { t } from 'ember-intl';
import preventDefault from 'ember-event-helpers/helpers/prevent-default';
import { eq, or } from 'ember-truth-helpers';

import UploadProgressModal from 'mssform/components/upload-progress-modal';
import userMassDir from 'mssform/helpers/user-mass-dir';
import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';

import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';
import type RequestService from 'mssform/services/request';
import type UploadProgressModalComponent from 'mssform/components/upload-progress-modal';

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormConfirmComponent extends Component<Signature> {
  @service declare request: RequestService;

  @action async submit(uploadProgressModal: UploadProgressModalComponent) {
    const { state, model, nav } = this.args;
    const { uploadVia } = model;

    if (uploadVia === 'webui') {
      const blobs = await uploadProgressModal.performUpload(state.files);

      model.files = blobs.map(({ signed_id }: { signed_id: string }) => signed_id);
    }

    const res = await this.request.fetch('/submissions', {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        submission: {
          tpa: model.tpa,
          upload_via: model.uploadVia,
          files: model.files,
          extraction_id: model.extractionId,
          entries_count: model.entriesCount,
          hold_date: model.holdDate,
          sequencer: model.sequencer,
          data_type: model.dataType,
          description: model.description,
          email_language: model.emailLanguage,

          contact_person: {
            email: model.contactPerson.email,
            full_name: model.contactPerson.fullName,
            affiliation: model.contactPerson.affiliation,
          },

          other_people: model.otherPeople.map((person) => {
            return {
              email: person.email,
              full_name: person.fullName,
            };
          }),
        },
      }),
    });

    const { id } = ((await res.json()) as { submission: { id: string } }).submission;

    model.id = id;

    nav.goNext();
  }

  <template>
    <UploadProgressModal as |modal|>
      <form {{on "submit" (preventDefault (fn this.submit modal))}} {{leavingConfirmation}}>
        <div class="vstack gap-3">
          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.prerequisites"}}</div>

            <div class="card-body">
              <ul class="mb-0">
                {{#if @state.maybeTpa}}
                  <li>{{t "submission-form.prerequisite.a1-2"}}</li>

                  {{#if @model.tpa}}
                    <li>{{t "submission-form.prerequisite.a2-1"}}</li>
                  {{else}}
                    <li>{{t "submission-form.prerequisite.a2-2"}}</li>
                  {{/if}}
                {{else}}
                  <li>{{t "submission-form.prerequisite.a1-1"}}</li>
                {{/if}}

                {{#if (eq @model.uploadVia "dfast")}}
                  <li>{{t "submission-form.files.a1"}}</li>
                {{else if (eq @model.uploadVia "webui")}}
                  <li>{{t "submission-form.files.a2"}}</li>
                {{else if (eq @model.uploadVia "mass_directory")}}
                  <li>{{t "submission-form.files.a3-html" htmlSafe=true userMassDir=(userMassDir)}}</li>
                {{/if}}
              </ul>
            </div>
          </div>

          {{#if @state.files}}
            <div class="card">
              <div class="card-header">{{t "submission-form.confirm.files"}}</div>

              <ul class="list-group list-group-flush">
                {{#each @state.files as |file|}}
                  <li class="list-group-item">{{file.name}}</li>
                {{/each}}
              </ul>
            </div>
          {{/if}}

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.entries-count"}}</div>

            <div class="card-body">
              {{@model.entriesCount}}
            </div>
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.hold-date"}}</div>

            <div class="card-body">
              {{or @model.holdDate (t "submission-form.confirm.release-immediately")}}
            </div>
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.contact-person"}}</div>

            <div class="card-body">
              {{#let @model.contactPerson as |person|}}
                {{person.fullName}}
                &lt;{{person.email}}&gt; ({{person.affiliation}})
              {{/let}}
            </div>
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.other-people"}}</div>

            {{#if @model.otherPeople}}
              <ul class="list-group list-group-flush">
                {{#each @model.otherPeople as |person|}}
                  <li class="list-group-item">{{person.fullName}} &lt;{{person.email}}&gt;</li>
                {{/each}}
              </ul>
            {{else}}
              <div class="card-body">
                {{t "submission-form.confirm.blank"}}
              </div>
            {{/if}}
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.sequencer-type"}}</div>

            <div class="card-body">
              {{t (concat "sequencers." @model.sequencer)}}
            </div>
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.data-type"}}</div>

            <div class="card-body">
              {{t (concat "data_types." @model.dataType)}}
            </div>
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.description"}}</div>

            <div class="card-body">
              {{#if @model.description}}
                <div style="white-space: pre-wrap;">{{@model.description}}</div>
              {{else}}
                {{t "submission-form.confirm.blank"}}
              {{/if}}
            </div>
          </div>

          <div class="card">
            <div class="card-header">{{t "submission-form.confirm.email-language"}}</div>

            <div class="card-body">
              {{t (concat "locales." @model.emailLanguage)}}
            </div>
          </div>

          <p>{{t "submission-form.confirm.confirm-message"}}</p>
        </div>

        <hr />

        <div class="hstack gap-3 justify-content-end">
          <a href class="btn btn-outline-primary px-4" {{on "click" (preventDefault @nav.goPrev)}}>{{t
              "submission-form.nav.back"
            }}</a>
          <button type="submit" class="btn btn-primary px-5">{{t "submission-form.confirm.submit"}}</button>
        </div>
      </form>
    </UploadProgressModal>
  </template>
}
