import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import UploadFiles from 'mssform/models/upload-files';

export default class SubmissionFormConfirmComponent extends Component {
  @service router;
  @service session;

  @action async submit(uploadProgressModal) {
    const blobs = await this.uploadFiles(uploadProgressModal);

    await this.session.authenticate('authenticator:appauth');

    const {model, nav} = this.args;

    model.files = blobs.map(({signed_id}) => signed_id);
    await model.save();

    nav.goNext();
  }

  async uploadFiles(progressModal) {
    const {fileSet} = this.args.state;

    const files = fileSet.files.mapBy('rawFile');

    if (files.length === 0) { return []; }

    const upload  = new UploadFiles(files);
    const perform = upload.perform();

    progressModal.show(upload);

    const blobs = await perform;

    progressModal.hide();

    return blobs;
  }
}
