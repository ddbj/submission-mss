import Component from '@glimmer/component';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import DfastExtraction from 'mssform/models/dfast-extraction';

import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFile } from 'mssform/models/submission-file';

interface CrossoverError {
  id: string;
}

interface ExtractionPayload {
  id: string;
  files: SubmissionFile[];
}

export interface Signature {
  Args: {
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFile, CrossoverError[]>;
  };
}

export default class DfastExtractorComponent extends Component<Signature> {
  @service declare errorModal: ErrorModalService;

  @tracked jobIdsText = '';
  @tracked extracting = false;
  @tracked files: SubmissionFile[] = [];
  @tracked error: { job_id: string; reason: string } | null = null;

  get jobIds() {
    return this.jobIdsText
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line !== '');
  }

  @action
  async extract() {
    this.extracting = true;
    this.files = [];

    try {
      const extraction = await DfastExtraction.create(getOwner(this)!, this.jobIds);

      await extraction.pollForResult(
        (payload) => {
          this.files = (payload as unknown as ExtractionPayload).files;

          this.args.onPoll(payload as unknown as ExtractionPayload);
        },
        (errorStr: string) => {
          this.errorModal.show(new Error(errorStr));
        },
      );
    } finally {
      this.extracting = false;
    }
  }
}
