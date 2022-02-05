import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class SubmissionFormFilesComponent extends Component {
  fileInputElement = null;

  @tracked dragOver = false;

  get isNextButtonDisabled() {
    const {submissionFileType, fileSet} = this.args.state;

    return submissionFileType && submissionFileType !== 'none' && fileSet.files.length === 0;
  }

  @action setSubmissionFileType(val) {
    const {model, state} = this.args;

    state.submissionFileType = val;
    model.dfast              = val === 'dfast';

    if (val === 'none') {
      state.fileSet.files.clear();
    }
  }

  @action selectFiles() {
    this.fileInputElement.click();
  }

  @action addFiles(files) {
    const {fileSet} = this.args.state;

    for (const file of files) {
      fileSet.add(file);
    }

    this.dragOver = false;
  }

  @action removeFile(file) {
    this.args.state.fileSet.remove(file);
  }

  @action goNext() {
    const {model, state, nav} = this.args;

    if (state.submissionFileType === 'none') {
      nav.goNext();
      return;
    }

    // files.length >= 2
    // paired
    // entries count > 0
    // contact person is exists

    const {annotationFiles, sequenceFiles}         = state.fileSet;
    const {holdDate, fullName, email, affiliation} = annotationFiles[0].parsedData;

    model.holdDate           = holdDate;
    state.releaseImmediately = !holdDate;

    model.contactPerson.fullName    = fullName;
    model.contactPerson.email       = email;
    model.contactPerson.affiliation = affiliation;

    model.entriesCount = sequenceFiles.reduce((acc, file) => acc + file.parsedData.entriesCount, 0);

    nav.goNext();
  }
}
