import Component from '@glimmer/component';
import { uniqueId, concat } from '@ember/helper';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import { t } from 'ember-intl';

import Modal from 'bootstrap/js/dist/modal';

import filesize from 'mssform/helpers/filesize';
import htmlSafe from 'mssform/helpers/html-safe';
import percentage from 'mssform/helpers/percentage';
import UploadFiles from 'mssform/models/upload-files';

import type CurrentUserService from 'mssform/services/current-user';
import type { SubmissionFile } from 'mssform/models/submission-file';

interface Signature {
  Blocks: {
    default: [UploadProgressModalComponent];
  };
}

export default class UploadProgressModalComponent extends Component<Signature> {
  @service declare currentUser: CurrentUserService;

  @tracked uploadFiles?: UploadFiles;

  modal!: Modal;

  setModal = modifier((element: HTMLElement) => {
    this.modal = new Modal(element);
  });

  @action hide() {
    this.modal.hide();
  }

  async performUpload(files: SubmissionFile[]) {
    if (!files.length) return [];

    this.uploadFiles = new UploadFiles(files);
    this.modal.show();

    let blobs;

    try {
      blobs = await this.uploadFiles.perform(this.currentUser);
    } finally {
      this.modal.hide();
    }

    return blobs;
  }

  <template>
    {{yield this}}

    {{#let (uniqueId) as |id|}}
      <div
        class="modal"
        tabindex="-1"
        role="dialog"
        aria-labelledby={{id}}
        aria-hidden="true"
        data-bs-backdrop="static"
        data-bs-keyboard="false"
        {{this.setModal}}
      >
        <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id={{id}}>{{t "upload-progress-modal.title"}}</h5>
            </div>

            <div class="modal-body vstack gap-2">
              {{#if this.uploadFiles}}
                {{#let this.uploadFiles.currentUpload as |upload|}}
                  {{#if upload}}
                    <div class="d-flex gap-2 align-items-center">
                      <b>{{upload.file.name}}</b>

                      {{#unless upload.isStarted}}
                        <div class="spinner-border spinner-border-sm text-primary" role="status">
                          <span class="visually-hidden">{{t "upload-progress-modal.calculating"}}</span>
                        </div>
                      {{/unless}}
                    </div>

                    <div class="progress">
                      {{#let (percentage this.uploadFiles.uploadedSize this.uploadFiles.totalSize) as |percentage|}}
                        <div
                          class="progress-bar"
                          role="progressbar"
                          style={{htmlSafe (concat "width: " percentage "%")}}
                          aria-valuenow={{percentage}}
                          aria-valuemin="0"
                          aria-valuemax="100"
                        ></div>
                      {{/let}}
                    </div>

                    <div class="text-body-secondary">
                      {{filesize this.uploadFiles.uploadedSize}}
                      /
                      {{filesize this.uploadFiles.totalSize}}
                    </div>
                  {{/if}}
                {{/let}}
              {{/if}}
            </div>

            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" {{on "click" this.hide}}>{{t
                  "upload-progress-modal.cancel"
                }}</button>
            </div>
          </div>
        </div>
      </div>
    {{/let}}
  </template>
}
