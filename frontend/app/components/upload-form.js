import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class UploadFormComponent extends Component {
  @service session;
  @service router;

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
    const blobs = await uploadProgressModal.performUpload(this.files);

    const body = new FormData();

    for (const blob of blobs) {
      body.append('files[]', blob.signed_id);
    }

    if (!(await this.session.renewToken())) {
      alert('Your session has been expired. Please re-login.');

      this.router.transitionTo('')
    }

    await fetch(`/api/submissions/${this.args.model.id}/uploads`, {
      method:  'POST',
      headers: this.session.authorizationHeader,
      body
    });

    this.isCompleted = true;
  }
}
