import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import { discardFiles } from 'mssform/models/submission-file';
import { collectCrossoverErrors, hasErrors } from 'mssform/utils/crossover-errors';

import type { SubmissionFileData } from 'mssform/models/submission-file';
import type { Validation } from 'mssform/utils/crossover-errors';

export type WhyNotSubmittable = 'no-via' | 'extracting' | 'rejected' | 'no-files' | 'errors' | 'reading';

// The files a form is about to send, and how they were chosen. Which checks
// they answer to is the form's decision: a new submission and a re-upload do
// not go by the same rules.
export default class FileSelection {
  @tracked via?: string;
  @tracked extractionId?: number;
  @tracked files: SubmissionFileData[] = [];

  // How the last extraction is getting on, while it matters: the files come
  // only when it is done, and not at all when it is turned down.
  @tracked extraction?: 'running' | 'rejected';

  #validations: Validation[];

  constructor(validations: Validation[]) {
    this.#validations = validations;
  }

  get crossoverErrors() {
    return collectCrossoverErrors(this.files, this.#validations);
  }

  // Why these files cannot be sent as they stand, if they cannot: said beside
  // the button that would send them, so that the submitter need not press it
  // to find out that it does nothing, nor guess why.
  get whyNotSubmittable(): WhyNotSubmittable | undefined {
    if (!this.via) return 'no-via';
    if (this.extraction === 'running') return 'extracting';
    if (this.extraction === 'rejected') return 'rejected';
    if (!this.files.length) return 'no-files';
    if (hasErrors(this.files, this.crossoverErrors)) return 'errors';
    if (this.files.some((file) => file.isParsing)) return 'reading';

    return undefined;
  }

  get isSubmittable() {
    return !this.whyNotSubmittable;
  }

  @action setVia(via: string) {
    this.discard();

    this.via = via;
    this.extraction = undefined;
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

  // A new extraction replaces whatever the last one found, before it has found
  // anything itself: until then there is nothing to send.
  @action onExtractStart() {
    this.extraction = 'running';
    this.extractionId = undefined;
    this.files = [];
  }

  // An extraction reports the files it has found so far, replacing what it
  // reported before.
  @action onExtractProgress({ id, state, files }: { id: number; state: string; files: SubmissionFileData[] }) {
    this.extractionId = id;
    this.files = files;

    if (state === 'rejected') this.extraction = 'rejected';
  }

  // Done with, one way or another -- including a request that failed, which
  // the error modal has told of.
  @action onExtractEnd() {
    if (this.extraction === 'running') this.extraction = undefined;
  }

  // Stops whatever is still running for these files.
  discard() {
    discardFiles(this.files);
  }
}
