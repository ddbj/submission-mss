import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { handleUploadError } from 'mssform/utils/error-handler';

export default class UploadFormComponent extends Component {
  @service fetch;

  @tracked uploadVia   = null;
  @tracked files       = [];
  @tracked isCompleted = false;

  get isSubmitButtonEnabled() {
    if (!this.files.length) { return false; }

    for (const file of this.files) {
      if (file.isParsing || file.errors.length) { return false; }
    }

    return true;
  }

  @action addFile(file) {
    this.files = [...this.files, file];
  }

  @action removeFile(file) {
    this.files = this.files.filter(f => f !== file);
  }

  @action async submit(uploadProgressModal) {
    const body = new FormData();

    body.set('upload_via', this.uploadVia);

    if (this.uploadVia == 'webui') {
      let blobs;

      try {
        blobs = await uploadProgressModal.performUpload(this.files);
      } catch (e) {
        handleUploadError(e, this.session);
        return;
      }

      for (const blob of blobs) {
        body.set('files[]', blob.signed_id);
      }
    }

    await this.fetch.request(`/api/submissions/${this.args.model.id}/uploads`, {
      method: 'POST',
      body
    });

    this.isCompleted = true;
  }
}
