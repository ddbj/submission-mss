import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';
import preventDefault from 'ember-event-helpers/helpers/prevent-default';
import { or } from 'ember-truth-helpers';
import set from 'ember-set-helper/helpers/set';
import sortBy from '@nullvoxpopuli/ember-composable-helpers/helpers/sort-by';
import mapBy from '@nullvoxpopuli/ember-composable-helpers/helpers/map-by';
import append from '@nullvoxpopuli/ember-composable-helpers/helpers/append';
import join from '@nullvoxpopuli/ember-composable-helpers/helpers/join';

import filesize from 'mssform/helpers/filesize';
import mapGet from 'mssform/helpers/map-get';
import sum from 'mssform/helpers/sum';
import dropTarget from 'mssform/modifiers/drop-target';
import FileListItem from 'mssform/components/file-list/item';
import { SubmissionFile } from 'mssform/models/submission-file';

interface CrossoverError {
  id: string;
}

export interface Signature {
  Args: {
    files: SubmissionFile[];
    crossoverErrors: Map<SubmissionFile, CrossoverError[]>;
    onAdd: (file: SubmissionFile) => void;
    onRemove: (file: SubmissionFile) => void;
  };
}

export default class FileListComponent extends Component<Signature> {
  allowedExtensions = SubmissionFile.allowedExtensions;
  fileInputElement: HTMLInputElement | null = null;

  @tracked dragOver = false;

  setFileInputElement = modifier((element: HTMLInputElement) => {
    this.fileInputElement = element;
  });

  @action selectFiles() {
    this.fileInputElement!.click();
  }

  @action addFiles(rawFiles: FileList) {
    this.dragOver = false;

    const files = Array.from(rawFiles).map((file) => SubmissionFile.fromRawFile(file));

    for (const file of files) {
      this.args.onAdd(file);

      void file.parse().then(() => {
        file.calculateDigest();
      });
    }
  }

  @action handleFileInput(event: Event) {
    const input = event.target as HTMLInputElement;

    if (input.files) {
      this.addFiles(input.files);
    }

    input.value = '';
  }

  <template>
    <style {{! template-lint-disable no-forbidden-elements }}>
      .drag-over * {
        pointer-events: none;
      }
    </style>

    <input
      type="file"
      multiple
      accept={{join ", " this.allowedExtensions}}
      class="d-none"
      {{this.setFileInputElement}}
      {{on "change" this.handleFileInput}}
      {{! template-lint-disable require-input-label }}
    />

    {{#if @files}}
      <div
        class="card {{if this.dragOver 'drag-over opacity-50 border-primary'}}"
        {{dropTarget this.addFiles enter=(set this "dragOver" true) leave=(set this "dragOver" false)}}
      >
        <ul class="list-group list-group-flush overflow-auto" style="max-height: 550px">
          {{#each (sortBy "name" @files) as |file|}}
            <FileListItem
              @file={{file}}
              {{! @glint-expect-error: mapGet returns unknown }}
              @errors={{append file.errors (or (mapGet @crossoverErrors file) (array))}}
              @onRemove={{@onRemove}}
            />
          {{/each}}
        </ul>

        <div class="card-footer d-flex justify-content-between align-items-center bg-white">
          <div>
            <button type="button" class="btn btn-outline-primary" {{on "click" (preventDefault this.selectFiles)}}>
              {{t "file-list.add-files"}}
            </button>
          </div>

          <div>
            {{t "file-list.stats" filesCount=@files.length totalFileSize=(filesize (sum (mapBy "size" @files)))}}
          </div>
        </div>
      </div>
    {{else}}
      <div
        class="card border-2 border-dashed {{if this.dragOver 'drag-over opacity-50 border-primary'}}"
        {{dropTarget this.addFiles enter=(set this "dragOver" true) leave=(set this "dragOver" false)}}
      >
        <div class="card-body py-5 text-center text-body-secondary">
          <a href="#" class="stretched-link" {{on "click" (preventDefault this.selectFiles)}}>
            {{t "file-list.select-files"}}
          </a>

          {{t "file-list.or-drag"}}
        </div>
      </div>
    {{/if}}
  </template>
}
