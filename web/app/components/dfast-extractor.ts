import Component from '@glimmer/component';
import { action } from '@ember/object';
import { getOwner } from '@ember/owner';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import DfastExtraction from 'mssform/models/dfast-extraction';

import type ErrorModalService from 'mssform/services/error-modal';
import type { Payload } from 'mssform/models/dfast-extraction';

type Signature = {
  Args: {
    onPoll: (payload: Payload) => void;
  };
};

export default class DfastExtractorComponent extends Component<Signature> {
  @service declare errorModal: ErrorModalService;

  @tracked jobIdsText = '';
  @tracked extracting = false;
  @tracked files: string[] = [];
  @tracked error = null;

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
        (payload: Payload) => {
          this.files = payload.files;

          this.args?.onPoll(payload);
        },
        (e: Payload['error']) => {
          this.errorModal.show(new Error(`Failed to fetch job (id=${e.job_id}). reason: ${e.reason}`));
        },
      );
    } finally {
      this.extracting = false;
    }
  }
}
