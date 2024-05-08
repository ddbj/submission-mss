import Component from '@glimmer/component';
import { getOwner } from '@ember/application';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import MassDirectoryExtraction from 'mssform/models/mass-directory-extraction';

export default class MassDirectoryExtractorComponent extends Component {
  @tracked files = [];

  fetchFiles = modifier(async () => {
    const extraction = await MassDirectoryExtraction.create(getOwner(this));

    await extraction.pollForResult(payload => {
      this.files = payload.files;

      this.args?.onPoll(payload);
    });
  });
}
