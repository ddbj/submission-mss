import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import UploadFiles from 'mssform/models/upload-files';

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
    const blobs = await uploadFiles(uploadProgressModal, this.files.map(f => f.rawFile));

    await this.session.authenticate('authenticator:appauth');

    const body = new FormData();
    const sids = blobs.map(({signed_id}) => signed_id);

    for (const sid of sids) {
      body.append('files[]', sid);
    }

    await fetch(`/api/submissions/${this.args.model.id}/uploads`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.session.data.authenticated.id_token}`
      },
      body
    });
  }
}

async function uploadFiles(progressModal, files) {
  if (files.length === 0) { return []; }

  const upload  = new UploadFiles(files);
  const perform = upload.perform();

  progressModal.show(upload);

  const blobs = await perform;

  progressModal.hide();

  return blobs;
}
