import Component from '@glimmer/component';
import { getOwner } from '@ember/application';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import MassDirectoryExtractorItem from 'mssform/components/mass-directory-extractor/item';
import errorsFor from 'mssform/helpers/errors-for';
import totalFileSize from 'mssform/helpers/total-file-size';
import MassDirectoryExtraction from 'mssform/models/mass-directory-extraction';

import type { SubmissionFile, SubmissionError } from 'mssform/models/submission-file';

interface ExtractionPayload {
  id: string;
  files: SubmissionFile[];
}

export interface Signature {
  Args: {
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFile, SubmissionError[]>;
  };
}

export default class MassDirectoryExtractorComponent extends Component<Signature> {
  @tracked files: SubmissionFile[] = [];

  get sortedFiles() {
    return [...this.files].sort((a, b) => a.name.localeCompare(b.name));
  }

  fetchFiles = modifier(() => {
    void (async () => {
      const extraction = await MassDirectoryExtraction.create(getOwner(this)!);

      await extraction.pollForResult((payload) => {
        this.files = (payload as unknown as ExtractionPayload).files;

        this.args.onPoll(payload as unknown as ExtractionPayload);
      });
    })();
  });

  <template>
    <div {{this.fetchFiles}} class="card">
      <ul class="list-group list-group-flush overflow-auto" style="max-height: 550px">
        {{#each this.sortedFiles key="name" as |file|}}
          <MassDirectoryExtractorItem @file={{file}} @errors={{errorsFor file @crossoverErrors}} />
        {{/each}}
      </ul>

      <div class="card-footer">
        {{this.files.length}}
        files,
        {{totalFileSize this.files}}
      </div>
    </div>
  </template>
}
