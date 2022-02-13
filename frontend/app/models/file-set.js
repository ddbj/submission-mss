import { tracked } from '@glimmer/tracking';

import { SubmissionFile } from 'mssform/models/submission-file';

export default class FileSet {
  allowedExtensions = SubmissionFile.allowedExtensions;

  @tracked files = [];

  get isEmpty() {
    return this.files.length === 0;
  }

  add(rawFile) {
    const file = SubmissionFile.createFromRawFile(rawFile);

    this.files = [...this.files, file];

    return file;
  }

  remove(file) {
    this.files = this.files.filter(f => f !== file);
  }
}
