import Component from '@glimmer/component';
import { uniqueId, concat } from '@ember/helper';
import { action } from '@ember/object';
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
import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFile } from 'mssform/models/submission-file';

interface Signature {
  Blocks: {
    default: [UploadProgressModalComponent];
  };
}

export default class UploadProgressModalComponent extends Component<Signature> {
  @service declare currentUser: CurrentUserService;
  @service declare errorModal: ErrorModalService;

  @tracked uploadFiles?: UploadFiles;

  modal!: Modal;

  #upload = new AbortController();

  willDestroy() {
    super.willDestroy();

    // Leaving the form abandons the upload: the browser's back button is not
    // covered by the `beforeunload` confirmation, and an upload left running
    // would go on to submit the application from a destroyed component.
    this.#upload.abort();
  }

  setModal = modifier((element: HTMLElement) => {
    this.modal = new Modal(element);

    return () => {
      // Destroying this element while the modal is open leaves Bootstrap
      // unaware, stranding its backdrop and the `modal-open` class on `<body>`:
      // the next page would be covered by an unclickable overlay and unable to
      // scroll. Hiding tears both down synchronously because this modal is not
      // animated. Disposing is left out on purpose; it would also drop the
      // application-wide error modal's window listeners, which share
      // Bootstrap's `.bs.modal` namespace.
      this.modal.hide();
    };
  });

  @action cancel() {
    // Close right away rather than waiting for the upload to notice: a checksum
    // still being calculated only sees the abort once it finishes.
    this.#upload.abort();
    this.modal.hide();
  }

  // Returns the uploaded blobs, or `undefined` if the upload failed, was
  // cancelled or was abandoned. A failure (e.g. a dropped connection) is
  // expected, so it is surfaced in the error modal rather than left to escape
  // as an unhandled rejection; callers must treat `undefined` as "stop here"
  // and not proceed with the submission.
  async performUpload(files: SubmissionFile[]) {
    if (!files.length) return [];

    // A controller per attempt: the one before it may have been cancelled, and
    // its signal would abort this upload before it starts.
    this.#upload = new AbortController();
    this.uploadFiles = new UploadFiles(files);

    this.modal.show();

    try {
      const blobs = await this.uploadFiles.perform(this.currentUser, this.#upload.signal);

      this.modal.hide();

      return blobs;
    } catch (error) {
      // The user cancelled or left the form, so there is nothing to report --
      // and both have hidden this modal already. Hiding it again here would
      // close the modal of a later attempt: an upload cancelled while its
      // checksum is being calculated only notices the abort once the checksum
      // finishes, by which time the user may have submitted again.
      if (error instanceof DOMException && error.name === 'AbortError') return undefined;

      // Hide this modal before showing the error modal. This is only safe while
      // this modal is not animated (no `fade`), so its backdrop is torn down
      // synchronously and does not race the error modal's backdrop.
      this.modal.hide();
      this.errorModal.show(error as Error);

      return undefined;
    }
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
              <button type="button" class="btn btn-secondary" {{on "click" this.cancel}}>{{t
                  "upload-progress-modal.cancel"
                }}</button>
            </div>
          </div>
        </div>
      </div>
    {{/let}}
  </template>
}
