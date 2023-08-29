import Component from '@glimmer/component';
import { action } from '@ember/object';
import { getOwner } from '@ember/application';
import { tracked } from '@glimmer/tracking';

import MassDirectoryExtraction from 'mssform/models/mass-directory-extraction';

export default class MassDirectoryExtractorComponent extends Component {
  @tracked files = [];

  @action
  async fetchFiles() {
    const extraction = await MassDirectoryExtraction.create(getOwner(this));

    await extraction.pollForResult(payload => {
      this.files = payload.files;

      this.args?.onPoll(payload);
    });
  }
}
