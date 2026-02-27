import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import type RequestService from 'mssform/services/request';
import type { SubmissionFile } from 'mssform/models/submission-file';
import type UploadProgressModalComponent from 'mssform/components/upload-progress-modal';

interface SubmissionModel {
  id: string;
}

export interface Signature {
  Args: {
    model: SubmissionModel;
  };
}

export default class UploadFormComponent extends Component<Signature> {
  @service declare request: RequestService;

  @tracked uploadVia: string | null = null;
  @tracked extractionId: string | null = null;
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

  @action setUploadVia(val: string) {
    this.uploadVia = val;
    this.files = [];
    this.extractionId = null;
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
    const attrs: Record<string, unknown> = {
      via: this.uploadVia,
    };

    if (this.uploadVia == 'webui') {
      const blobs = await uploadProgressModal.performUpload(this.files);

      attrs.files = blobs.map((blob: { signed_id: string }) => blob.signed_id);
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
