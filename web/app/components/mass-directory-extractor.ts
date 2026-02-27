import Component from '@glimmer/component';
import { getOwner } from '@ember/application';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import MassDirectoryExtraction from 'mssform/models/mass-directory-extraction';

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

export default class MassDirectoryExtractorComponent extends Component<Signature> {
  @tracked files: SubmissionFile[] = [];

  fetchFiles = modifier(async () => {
    const extraction = await MassDirectoryExtraction.create(getOwner(this)!);

    await extraction.pollForResult((payload) => {
      this.files = (payload as unknown as ExtractionPayload).files;

      this.args.onPoll(payload as unknown as ExtractionPayload);
    });
  });
}
