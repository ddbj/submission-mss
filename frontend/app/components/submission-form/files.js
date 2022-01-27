import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class SubmissionFormFilesComponent extends Component {
  fileInputElement         = null;
  annotationFileExtensions = ['.ann', '.annt.tsv', '.ann.txt'];
  sequenceFileExtensions   = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];

  @tracked dragOver = false;

  get isFulfilled() {
    const {state} = this.args;

    return state.submissionFileType === 'none' || state.files;
  }

  @action setSubmissionFileType(val) {
    const {model, state} = this.args;

    state.submissionFileType = val;
    model.dfast              = val === 'dfast';

    if (val === 'none') {
      state.files.clear();
    }
  }

  @action selectFiles() {
    this.fileInputElement.click();
  }

  @action addFiles(files) {
    this.args.state.files.pushObjects(Array.from(files));

    this.dragOver = false;
  }

  @action removeFile(file) {
    this.args.state.files.removeObject(file);
  }
}
