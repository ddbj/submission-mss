import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import type RequestService from 'mssform/services/request';
import type Submission from 'mssform/models/submission';
import type UploadProgressModalComponent from 'mssform/components/upload-progress-modal';
import type SubmissionFile from 'mssform/models/submission-file';

interface Signature {
  Args: {
    model: Submission;
  };
}

export default class UploadFormComponent extends Component<Signature> {
  @service declare request: RequestService;

  @tracked uploadVia?: Submission['uploadVia'];
  @tracked extractionId?: Submission['extractionId'];
  @tracked files: SubmissionFile[] = [];
  @tracked isCompleted = false;
  @tracked crossoverErrors = new Map(); // always empty

  get isSubmitButtonEnabled() {
    const { uploadVia, files } = this;

    if (!uploadVia) return false;
    if (!files.length) return false;

    for (const file of files) {
      if (file.isParsing || file.errors.length) return false;
    }

    return true;
  }

  @action setUploadVia(val: Submission['uploadVia']) {
    this.uploadVia = val;
    this.files = [];
    this.extractionId = undefined;
  }

  @action onExtractProgress({ id, files }: { id: string; files: SubmissionFile[] }) {
    this.extractionId = id;
    this.files = files;
  }

  @action addFile(file: SubmissionFile) {
    this.files = [...this.files, file];
  }

  @action removeFile(file: SubmissionFile) {
    this.files = this.files.filter((f) => f !== file);
  }

  @action async submit(uploadProgressModal: UploadProgressModalComponent) {
    const attrs: {
      via: Submission['uploadVia'];
      files?: string[];
      extraction_id?: string;
    } = {
      via: this.uploadVia,
    };

    if (this.uploadVia == 'webui') {
      const blobs = await uploadProgressModal.performUpload(this.files);

      attrs.files = blobs.map((blob) => blob.signed_id);
    } else {
      attrs.extraction_id = this.extractionId;
    }

    await this.request.fetchWithModal(`/submissions/${this.args.model.id}/uploads`, {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        upload: attrs,
      }),
    });

    this.isCompleted = true;
  }
}
