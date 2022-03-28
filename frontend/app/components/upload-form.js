import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { handleAppAuthHTTPError, handleFetchError, handleUploadError } from 'mssform/utils/error-handler';

export default class UploadFormComponent extends Component {
  @service session;

  @tracked files           = [];
  @tracked crossoverErrors = new Map();
  @tracked isCompleted     = false;

  get isSubmitButtonEnabled() {
    if (!this.files.length) { return false; }

    for (const file of this.files) {
      if (file.isParsing || file.errors.length) { return false; }
    }

    for (const errors of this.crossoverErrors.values()) {
      if (errors.length) { return false; }
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
    let blobs;

    try {
      blobs = await uploadProgressModal.performUpload(this.files);
    } catch (e) {
      handleUploadError(e, this.session);
      return;
    }

    const body = new FormData();

    for (const blob of blobs) {
      body.append('files[]', blob.signed_id);
    }

    try {
      await this.session.renewToken();
    } catch (e) {
      handleAppAuthHTTPError(e, this.session);
      return;
    }

    const res = await fetch(`/api/submissions/${this.args.model.id}/uploads`, {
      method:  'POST',
      headers: this.session.authorizationHeader,
      body
    });

    if (!res.ok) {
      handleFetchError(res, this.session);
      return;
    }

    this.isCompleted = true;
  }
}
