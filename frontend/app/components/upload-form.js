import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import FileSet from 'mssform/models/file-set';
import UploadFiles from 'mssform/models/upload-files';

export default class UploadFormComponent extends Component {
  @service session;

  fileSet         = new FileSet();
  crossoverErrors = new Map();

  @action async submit(uploadProgressModal) {
    const {files} = this.fileSet;
    const blobs   = await uploadFiles(uploadProgressModal, files.map(f => f.rawFile));

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
