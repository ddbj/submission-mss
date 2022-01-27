import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import UploadFiles from 'mssform-web/models/upload-files';

export default class SubmissionFormSubmitComponent extends Component {
  @service session;

  @action async submit(uploadProgressModal) {
    const blobs = await this.uploadFiles(uploadProgressModal);

    await this.session.authenticate('authenticator:appauth');

    const {model} = this.args;

    model.files = blobs.map(({signed_id}) => signed_id);

    await model.save();
  }

  async uploadFiles(progressModal) {
    const {files} = this.args.state;

    if (files.length === 0) { return []; }

    const upload  = new UploadFiles(files);
    const perform = upload.perform();

    progressModal.show(upload);

    const blobs = await perform;

    progressModal.hide();

    return blobs;
  }
}
