import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import UploadFiles from 'mssform/models/upload-files';

export default class SubmissionFormConfirmComponent extends Component {
  @service router;
  @service session;

  @action async submit(uploadProgressModal) {
    const {state, model, nav} = this.args;

    const blobs = await uploadFiles(uploadProgressModal, state.files.map(f => f.rawFile));

    await this.session.authenticate('authenticator:appauth');

    model.files = blobs.map(({signed_id}) => signed_id);
    await model.save();

    nav.goNext();
  }
}

async function uploadFiles(progressModal, files) {
  if (files.length === 0) { return []; }

  const upload = new UploadFiles(files);

  progressModal.show(upload);

  const blobs = await upload.perform();

  progressModal.hide();

  return blobs;
}
