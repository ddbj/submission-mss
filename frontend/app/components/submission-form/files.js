import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import { SubmissionFile } from 'mssform/models/submission-file';

export default class SubmissionFormFilesComponent extends Component {
  fileInputElement = null;

  @tracked dragOver = false;

  get isNextButtonDisabled() {
    const {submissionFileType, fileSet} = this.args.state;

    return !submissionFileType           ? true  :
           submissionFileType === 'none' ? false :
           !fileSet.files.length         ? true  :
                                           fileSet.files.some(({isParsing, errors}) => isParsing || errors.length);
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

  @action async addFiles(files) {
    this.dragOver = false;

    const {fileSet} = this.args.state;

    const promises = Array.from(files).map((rawFile) => {
      const file = SubmissionFile.createFromRawFile(rawFile);

      fileSet.add(file);

      return file.parse();
    });

    await Promise.all(promises);
  }

  @action removeFile(file) {
    this.args.state.fileSet.remove(file);
  }

  @action goNext() {
    this.setParsedData();

    this.args.nav.goNext();
  }

  setParsedData() {
    const {state, model}                = this.args;
    const {submissionFileType, fileSet} = state;

    if (submissionFileType === 'none') { return; }

    const {contactPerson, holdDate} = fileSet.files.find(({isAnnotation}) => isAnnotation).parsedData;

    Object.assign(model.contactPerson, contactPerson || {});
    state.isContactPersonReadonly = !!contactPerson;

    model.holdDate           = holdDate;
    state.releaseImmediately = !holdDate;

    model.entriesCount = fileSet.files.filter(({isSequence}) => isSequence).reduce((acc, file) => {
      return acc + file.parsedData.entriesCount;
    }, 0);
  }
}
