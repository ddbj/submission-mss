import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { trackedArray } from '@ember/reactive/collections';

import { t } from 'ember-intl';
import { eq, not } from 'ember-truth-helpers';
import pageTitle from 'ember-page-title/helpers/page-title';
import svgJar from 'ember-svg-jar/helpers/svg-jar';

import DfastExtractor from 'mssform/components/dfast-extractor';
import FileList from 'mssform/components/file-list';
import SupportedFileTypes from 'mssform/components/file-list/supported-file-types';
import MassDirectoryExtractor from 'mssform/components/mass-directory-extractor';
import RadioGroup from 'mssform/components/radio-group';
import UploadProgressModal from 'mssform/components/upload-progress-modal';
import userMassDir from 'mssform/helpers/user-mass-dir';
import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';

import type RequestManager from '@ember-data/request';
import type { SubmissionFile, SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';
import type UploadProgressModalComponent from 'mssform/components/upload-progress-modal';

interface DirectUploadBlob {
  signed_id: string;
}

interface SubmissionModel {
  id?: string;
}

export interface Signature {
  Args: {
    model: SubmissionModel;
  };
}

export default class UploadFormComponent extends Component<Signature> {
  @service declare requestManager: RequestManager;

  @tracked uploadVia: string | null = null;
  @tracked extractionId: number | null = null;
  files: SubmissionFileData[] = trackedArray();
  @tracked isCompleted = false;
  @tracked crossoverErrors = new Map<SubmissionFileData, SubmissionError[]>();

  get isSubmitButtonEnabled() {
    const { uploadVia, files } = this;

    if (!uploadVia) return false;
    if (!files.length) return false;

    for (const file of files) {
      if (file.isParsing || file.errors?.length) return false;
    }

    return true;
  }

  @action setUploadVia(val: string) {
    this.uploadVia = val;
    this.files.length = 0;
    this.extractionId = null;
  }

  @action onExtractProgress({ id, files }: { id: number; files: SubmissionFileData[] }) {
    this.extractionId = id;
    this.files.length = 0;
    this.files.push(...files);
  }

  @action addFile(file: SubmissionFileData) {
    this.files.push(file);
  }

  @action removeFile(file: SubmissionFileData) {
    this.files.splice(this.files.indexOf(file), 1);
  }

  @action async submit(uploadProgressModal: UploadProgressModalComponent, event: Event) {
    event.preventDefault();
    const attrs: Record<string, unknown> = {
      via: this.uploadVia,
    };

    if (this.uploadVia == 'webui') {
      const blobs = (await uploadProgressModal.performUpload(
        this.files as SubmissionFile[],
      )) as unknown as DirectUploadBlob[];

      attrs['files'] = blobs.map((blob) => blob.signed_id);
    } else {
      attrs['extraction_id'] = this.extractionId;
    }

    await this.requestManager.request({
      url: `/submissions/${this.args.model.id}/uploads`,
      method: 'POST',

      data: {
        upload: attrs,
      },
    });

    this.isCompleted = true;
  }

  <template>
    {{pageTitle (t "upload-form.title")}}

    {{#if this.isCompleted}}
      {{t "upload-form.complete-html" htmlSafe=true}}

      <LinkTo @route="home">{{t "go-to-home"}}</LinkTo>
    {{else}}
      <h1 class="display-6 my-4">{{t "upload-form.title"}}</h1>

      {{t "upload-form.description-html" massId=@model.id htmlSafe=true}}

      <UploadProgressModal as |modal|>
        <form {{on "submit" (fn this.submit modal)}} {{leavingConfirmation}}>
          <div class="vstack gap-3">
            <div class="card">
              <div class="card-body">
                <RadioGroup as |group|>
                  <div class="form-check">
                    <group.radio as |radio|>
                      <radio.input
                        checked={{eq this.uploadVia "dfast"}}
                        required
                        class="form-check-input"
                        {{on "change" (fn this.setUploadVia "dfast")}}
                      />

                      <radio.label class="form-check-label">
                        {{t "submission-form.files.a1"}}
                      </radio.label>
                    </group.radio>
                  </div>

                  <div class="form-check">
                    <group.radio as |radio|>
                      <radio.input
                        checked={{eq this.uploadVia "webui"}}
                        required
                        class="form-check-input"
                        {{on "change" (fn this.setUploadVia "webui")}}
                      />

                      <radio.label class="form-check-label">
                        {{t "submission-form.files.a2"}}
                      </radio.label>
                    </group.radio>
                  </div>

                  <div class="hstack gap-3">
                    <div class="form-check">
                      <group.radio as |radio|>
                        <radio.input
                          checked={{eq this.uploadVia "mass_directory"}}
                          required
                          class="form-check-input"
                          {{on "change" (fn this.setUploadVia "mass_directory")}}
                        />

                        <radio.label class="form-check-label">
                          {{t "submission-form.files.a3-html" htmlSafe=true userMassDir=(userMassDir)}}
                        </radio.label>

                        {{t "submission-form.files.a3-note-html" htmlSafe=true}}
                      </group.radio>
                    </div>

                    <small>
                      <a href={{t "submission-form.files.a3-help-url"}} target="_blank" rel="noopener noreferrer">
                        {{svgJar "question-16" class="octicon" width="14px" style="margin-top: 2px"}}
                        {{t "submission-form.files.a3-help-text"}}
                      </a>
                    </small>
                  </div>
                </RadioGroup>
              </div>
            </div>

            {{#if (eq this.uploadVia "dfast")}}
              <DfastExtractor @onPoll={{this.onExtractProgress}} @crossoverErrors={{this.crossoverErrors}} />
            {{else if (eq this.uploadVia "webui")}}
              <div class="card">
                <div class="card-body">
                  {{t "upload-form.instructions-html" htmlSafe=true}}

                  <SupportedFileTypes />

                  <FileList
                    @files={{this.files}}
                    @crossoverErrors={{this.crossoverErrors}}
                    @onAdd={{this.addFile}}
                    @onRemove={{this.removeFile}}
                  />
                </div>
              </div>
            {{else if (eq this.uploadVia "mass_directory")}}
              <MassDirectoryExtractor @onPoll={{this.onExtractProgress}} @crossoverErrors={{this.crossoverErrors}} />
            {{/if}}
          </div>

          {{#if this.uploadVia}}
            <hr />

            <div class="text-end">
              <button type="submit" disabled={{not this.isSubmitButtonEnabled}} class="btn btn-primary px-5">{{t
                  "upload-form.upload"
                }}</button>
            </div>
          {{/if}}
        </form>
      </UploadProgressModal>
    {{/if}}
  </template>
}
