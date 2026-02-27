import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';

import errorsFor from 'mssform/helpers/errors-for';
import totalFileSize from 'mssform/helpers/total-file-size';
import dropTarget from 'mssform/modifiers/drop-target';
import FileListItem from 'mssform/components/file-list/item';
import { SubmissionFile } from 'mssform/models/submission-file';

import type { SubmissionError } from 'mssform/models/submission-file';

export interface Signature {
  Args: {
    files: SubmissionFile[];
    crossoverErrors: Map<SubmissionFile, SubmissionError[]>;
    onAdd: (file: SubmissionFile) => void;
    onRemove: (file: SubmissionFile) => void;
  };
}

export default class FileListComponent extends Component<Signature> {
  fileInputElement: HTMLInputElement | null = null;

  @tracked dragOver = false;

  get acceptExtensions() {
    return SubmissionFile.allowedExtensions.join(', ');
  }

  get sortedFiles() {
    return [...this.args.files].sort((a, b) => a.name.localeCompare(b.name));
  }

  enterDragOver = () => {
    this.dragOver = true;
  };

  leaveDragOver = () => {
    this.dragOver = false;
  };

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
      accept={{this.acceptExtensions}}
      class="d-none"
      {{this.setFileInputElement}}
      {{on "change" this.handleFileInput}}
      {{! template-lint-disable require-input-label }}
    />

    {{#if @files}}
      <div
        class="card {{if this.dragOver 'drag-over opacity-50 border-primary'}}"
        {{dropTarget this.addFiles enter=this.enterDragOver leave=this.leaveDragOver}}
      >
        <ul class="list-group list-group-flush overflow-auto" style="max-height: 550px">
          {{#each this.sortedFiles as |file|}}
            <FileListItem @file={{file}} @errors={{errorsFor file @crossoverErrors}} @onRemove={{@onRemove}} />
          {{/each}}
        </ul>

        <div class="card-footer d-flex justify-content-between align-items-center bg-white">
          <div>
            <button type="button" class="btn btn-outline-primary" {{on "click" this.selectFiles}}>
              {{t "file-list.add-files"}}
            </button>
          </div>

          <div>
            {{t "file-list.stats" filesCount=@files.length totalFileSize=(totalFileSize @files)}}
          </div>
        </div>
      </div>
    {{else}}
      <div
        class="card border-2 border-dashed {{if this.dragOver 'drag-over opacity-50 border-primary'}}"
        {{dropTarget this.addFiles enter=this.enterDragOver leave=this.leaveDragOver}}
      >
        <div class="card-body py-5 text-center text-body-secondary">
          <button
            type="button"
            class="stretched-link btn btn-link p-0 border-0 align-baseline"
            {{on "click" this.selectFiles}}
          >
            {{t "file-list.select-files"}}
          </button>

          {{t "file-list.or-drag"}}
        </div>
      </div>
    {{/if}}
  </template>
}
