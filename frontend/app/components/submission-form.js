import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import UploadFiles from 'mssform-web/models/upload-files';

export default class SubmissionFormComponent extends Component {
  @service router;
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

    const {model} = this.args;
    const files   = blobs.map(({signed_id}) => signed_id);

    model.files = files;
    await model.save();

    this.router.transitionTo('submission.submitted', model);
  }

  async uploadFiles(progressModal) {
    if (this.files.length === 0) { return []; }

    const upload  = new UploadFiles(this.files);
    const perform = upload.perform();

    progressModal.show(upload);

    const blobs = await perform;

    progressModal.hide();

    return blobs;
  }
}
