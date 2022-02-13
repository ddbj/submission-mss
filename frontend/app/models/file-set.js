import { tracked } from '@glimmer/tracking';

import { SubmissionFile } from 'mssform/models/submission-file';

export default class FileSet {
  allowedExtensions = SubmissionFile.allowedExtensions;

  @tracked files = [];

  get isEmpty() {
    return this.files.length === 0;
  }

  add(file) {
    this.files = [...this.files, file];
  }

  remove(file) {
    this.files = this.files.filter(f => f !== file);
  }

  get errors() {
    return this.annotationFileErrors;
  }

  get annotationFileErrors() {
    // files.length >= 2
    // paired
    // entries count > 0

    const files = this.files.filter(({isAnnotation, isParseSucceeded}) => isAnnotation && isParseSucceeded);

    if (!files.length) { return []; }

    const contactPersonSet = new Set();
    const holdDateSet      = new Set();

    for (const file of files) {
      const {contactPerson, holdDate} = file.parsedData;

      contactPersonSet.add(JSON.stringify(contactPerson));
      holdDateSet.add(holdDate);
    }

    const errors = [];

    if (contactPersonSet.size > 1) {
      errors.push('Contact person in all annotation files must be the same.');
    }

    if (holdDateSet.size > 1) {
      errors.push('Hold date in all annotation files must be the same.');
    }

    return errors;
  }
}
