import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import { discardFiles } from 'mssform/models/submission-file';
import { collectCrossoverErrors, hasBlockingErrors } from 'mssform/utils/crossover-errors';

import type { SubmissionFileData } from 'mssform/models/submission-file';
import type { Validation } from 'mssform/utils/crossover-errors';

// The files a form is about to send, and how they were chosen. Which checks
// they answer to is the form's decision: a new submission and a re-upload do
// not go by the same rules.
export default class FileSelection {
  @tracked via?: string;
  @tracked extractionId?: number;
  @tracked files: SubmissionFileData[] = [];

  #validations: Validation[];

  constructor(validations: Validation[]) {
    this.#validations = validations;
  }

  get crossoverErrors() {
    return collectCrossoverErrors(this.files, this.#validations);
  }

  // Whether these files can be sent as they stand.
  get isSubmittable() {
    if (!this.via) return false;
    if (!this.files.length) return false;

    return !hasBlockingErrors(this.files, this.crossoverErrors);
  }

  @action setVia(via: string) {
    this.discard();

    this.via = via;
    this.extractionId = undefined;
    this.files = [];
  }

  @action addFile(file: SubmissionFileData) {
    this.files = [...this.files, file];
  }

  @action removeFile(file: SubmissionFileData) {
    discardFiles([file]);

    this.files = this.files.filter((f) => f !== file);
  }

  // An extraction reports the files it has found so far, replacing what it
  // reported before.
  @action onExtractProgress({ id, files }: { id: number; files: SubmissionFileData[] }) {
    this.extractionId = id;
    this.files = files;
  }

  // Stops whatever is still running for these files.
  discard() {
    discardFiles(this.files);
  }
}
