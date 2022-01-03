import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import DirectUpload from 'mssform-web/models/direct-upload';

export default class SubmissionFormComponent extends Component {
  @service appauth;
  @service session;

  @tracked determinedByOwnStudy = null;
  @tracked fileIsPrepared       = null;
  @tracked files                = A([]);
  @tracked confirmed            = false;
  @tracked dragOver             = false;

  fileInputElement = null;

  @action setDeterminedByOwnStudy(val) {
    this.determinedByOwnStudy = val;
    this.args.model.tpa       = null;
  }

  @action setFileIsPrepared(val) {
    this.fileIsPrepared = val;

    this.setDfast(null);
  }

  @action setDfast(val) {
    this.args.model.dfast = val;

    this.setDataType(null);
  }

  @action setDataType(val) {
    this.args.model.dataType          = val;
    this.args.model.dataTypeOtherText = null;
    this.args.model.accessionNumber   = null;
  }

  @action selectFiles() {
    this.fileInputElement.click();
  }

  @action addFiles(files) {
    this.files.pushObjects(Array.from(files));

    this.dragOver = false;
  }

  @action removeFile(file) {
    this.files.removeObject(file);
  }

  @action async submit(uploadProgressModal) {
    const blobs = await this.uploadFiles(uploadProgressModal);

    await this.session.authenticate('authenticator:appauth');

    const res = await fetch('/api/submissions', {
      method: 'POST',

      headers: {
        Authorization: `Bearer ${this.session.data.authenticated.id_token}`,
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        submission: {
          ...this.args.model.toPayload(),

          files: blobs.map(({signed_id}) => signed_id)
        }
      })
    });

    if (!res.ok) {
      throw new Error(res.statusText);
    }

    console.log(await res.json());
  }

  async uploadFiles(progressModal) {
    if (this.files.length === 0) { return []; }

    const upload  = new DirectUpload(this.files);
    const perform = upload.perform();

    progressModal.show(upload);

    const blobs = await perform;

    progressModal.hide();

    return blobs;
  }
}
