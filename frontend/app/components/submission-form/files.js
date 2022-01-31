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
}
