import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { isPresent } from '@ember/utils';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import UploadFiles from 'mssform-web/models/upload-files';

export default class SubmissionFormComponent extends Component {
  @service router;
  @service session;

  @tracked determinedByOwnStudy = null;
  @tracked submissionFileType   = null;
  @tracked files                = A([]);
  @tracked releaseImmediately   = true;
  @tracked confirmed            = false;
  @tracked dragOver             = false;

  fileInputElement = null;

  annotationFileExtensions = ['.ann', '.annt.tsv', '.ann.txt', '.ano.tsv'];
  sequenceFileExtensions   = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq', '.sequence.ddbj'];

  @action setDeterminedByOwnStudy(val) {
    this.determinedByOwnStudy = val;

    this.args.model.tpa = val ? false : null;
  }

  @action setSubmissionFileType(val) {
    this.submissionFileType = val;
    this.args.model.dfast   = val === 'dfast';

    if (val === 'none') {
      this.files.clear();
    }
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

  @action setReleaseImmediately(val) {
    this.releaseImmediately = val;

    if (val) {
      this.args.model.holdDate = null;
    }
  }

  @action addOtherPerson() {
    this.args.model.otherPeople.createRecord();
  }

  @action removeOtherPerson(person) {
    person.destroyRecord();
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
