import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class UploadFormComponent extends Component {
  @service request;

  @tracked uploadVia = null;
  @tracked extractionId = null;
  @tracked files = [];
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

  @action setUploadVia(val) {
    this.uploadVia = val;
    this.files = [];
    this.extractionId = null;
  }

  @action onExtractProgress({ id, files }) {
    this.extractionId = id;
    this.files = files;
  }

  @action addFile(file) {
    this.files = [...this.files, file];
  }

  @action removeFile(file) {
    this.files = this.files.filter((f) => f !== file);
  }

  @action async submit(uploadProgressModal) {
    const attrs = {
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
