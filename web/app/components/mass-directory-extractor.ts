import Component from '@glimmer/component';
import { getOwner } from '@ember/owner';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import MassDirectoryExtraction from 'mssform/models/mass-directory-extraction';

import type { Payload } from 'mssform/models/mass-directory-extraction';

interface Signature {
  Args: {
    onPoll: (payload: Payload) => void;
  };
}

export default class MassDirectoryExtractorComponent extends Component<Signature> {
  @tracked files: string[] = [];

  fetchFiles = modifier(() => {
    void (async () => {
      const extraction = await MassDirectoryExtraction.create(getOwner(this)!);

      await extraction.pollForResult((payload) => {
        this.files = payload.files;

        this.args?.onPoll(payload);
      });
    })();
  });
}
