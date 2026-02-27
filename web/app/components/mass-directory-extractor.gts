import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { getOwner } from '@ember/application';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';
import { or } from 'ember-truth-helpers';
import sortBy from '@nullvoxpopuli/ember-composable-helpers/helpers/sort-by';
import mapBy from '@nullvoxpopuli/ember-composable-helpers/helpers/map-by';
import append from '@nullvoxpopuli/ember-composable-helpers/helpers/append';

import MassDirectoryExtractorItem from 'mssform/components/mass-directory-extractor/item';
import filesize from 'mssform/helpers/filesize';
import mapGet from 'mssform/helpers/map-get';
import sum from 'mssform/helpers/sum';
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

  <template>
    <div {{this.fetchFiles}} class="card">
      <ul class="list-group list-group-flush overflow-auto" style="max-height: 550px">
        {{#each (sortBy "name" this.files) key="name" as |file|}}
          <MassDirectoryExtractorItem
            @file={{file}}
            @errors={{append file.errors (or (mapGet @crossoverErrors file) (array))}}
          />
        {{/each}}
      </ul>

      <div class="card-footer">
        {{this.files.length}}
        files,
        {{filesize (sum (mapBy "size" this.files))}}
      </div>
    </div>
  </template>
}
