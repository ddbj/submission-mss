import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class UploadFormComponent extends Component {
  @service session;

  @tracked files           = [];
  @tracked crossoverErrors = new Map();

  @action addFile(file) {
    this.files = [...this.files, file];
  }

  @action removeFile(file) {
    this.files = this.files.filter(f => f !== file);
  }

  @action async submit(uploadProgressModal) {
    const blobs = await uploadProgressModal.performUpload(this.files.map(f => f.rawFile));

    const body = new FormData();

    for (const blob of blobs) {
      body.append('files[]', blob.signed_id);
    }

    await this.session.authenticate('authenticator:appauth');

    await fetch(`/api/submissions/${this.args.model.id}/uploads`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.session.data.authenticated.id_token}`
      },
      body
    });
  }
}
