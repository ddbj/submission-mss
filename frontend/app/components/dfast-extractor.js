import Component from '@glimmer/component';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { tracked } from '@glimmer/tracking';

import DfastExtraction from 'mssform/models/dfast-extraction';

export default class DfastExtractorComponent extends Component {
  @tracked extracting = false;
  @tracked jobIdsText = '';
  @tracked files      = null;

  get jobIds() {
    return this.jobIdsText.split('\n').map(line => line.trim()).filter(line => line !== '');
  }

  @action
  async extract() {
    this.extracting = true;

    try {
      const extraction = await DfastExtraction.create(getOwner(this), this.jobIds);

      await extraction.pollForResult(payload => {
        this.files = payload.files;

        this.args?.onPoll(payload);
      });
    } finally {
      this.extracting = false;
    }
  }
}
