import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { t } from 'ember-intl';
import pageTitle from 'ember-page-title/helpers/page-title';

import FileChooser from 'mssform/components/file-chooser';
import UploadProgressModal from 'mssform/components/upload-progress-modal';
import FileSelection from 'mssform/models/file-selection';
import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';
import { validateDuplicates, validateSameness } from 'mssform/utils/crossover-errors';

import type { RequestManager } from '@warp-drive/core';
import type { SubmissionFile } from 'mssform/models/submission-file';
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

  @tracked isCompleted = false;

  // Re-uploading often means replacing one half of a pair, so a lone annotation
  // or sequence file is expected here -- unlike in the submission form, which
  // takes whole pairs only. The rest still holds: the same name twice is a
  // mistake, and the annotation files sent together have to agree on the
  // contact person and the hold date the submission already has.
  selection = new FileSelection([validateDuplicates, validateSameness]);

  willDestroy() {
    super.willDestroy();

    this.selection.discard();
  }

  @action async submit(uploadProgressModal: UploadProgressModalComponent, event: Event) {
    event.preventDefault();

    const { selection } = this;

    const attrs: Record<string, unknown> = {
      via: selection.via,
    };

    if (selection.via === 'webui') {
      const blobs = (await uploadProgressModal.performUpload(selection.files as SubmissionFile[])) as unknown as
        DirectUploadBlob[] | undefined;

      // The upload failed and was surfaced in the error modal, or it was
      // cancelled or abandoned along with the form. Either way, stop here.
      if (!blobs) return;

      attrs['files'] = blobs.map((blob) => blob.signed_id);
    } else {
      attrs['extraction_id'] = selection.extractionId;
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
          <FileChooser @selection={{this.selection}}>
            <:instructions>{{t "upload-form.instructions-html" htmlSafe=true}}</:instructions>
          </FileChooser>

          {{#if this.selection.via}}
            <hr />

            <div class="text-end">
              <button type="submit" disabled={{not this.selection.isSubmittable}} class="btn btn-primary px-5">{{t
                  "upload-form.upload"
                }}</button>
            </div>
          {{/if}}
        </form>
      </UploadProgressModal>
    {{/if}}
  </template>
}
