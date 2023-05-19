import Component from '@glimmer/component';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { tracked } from '@glimmer/tracking';

import DfastExtraction from 'mssform/models/dfast-extraction';

export default class DfastExtractorComponent extends Component {
  @tracked jobIdsText = '';
  @tracked extracting = false;
  @tracked files      = [];
  @tracked error      = null;

  get jobIds() {
    return this.jobIdsText.split('\n').map(line => line.trim()).filter(line => line !== '');
  }

  @action
  async extract() {
    this.extracting = true;
    this.files      = [];
    this.error      = null;

    try {
      const extraction = await DfastExtraction.create(getOwner(this), this.jobIds);

      await extraction.pollForResult(payload => {
        this.files = payload.files;

        this.args?.onPoll(payload);
      }, error => {
        this.error = error;
      });
    } finally {
      this.extracting = false;
    }
  }
}
