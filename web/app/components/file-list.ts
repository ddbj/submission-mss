import Component from '@glimmer/component';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

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
}
