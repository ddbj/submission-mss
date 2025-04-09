import Component from '@glimmer/component';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import SubmissionFile from 'mssform/models/submission-file';

interface Signature {
  Args: {
    onAdd: (file: SubmissionFile) => void;
  };
}

export default class FileListComponent extends Component<Signature> {
  allowedExtensions = SubmissionFile.allowedExtensions;
  fileInputElement?: HTMLInputElement = undefined;

  @tracked dragOver = false;

  setFileInputElement = modifier((element: HTMLInputElement) => {
    this.fileInputElement = element;
  });

  @action selectFiles() {
    this.fileInputElement!.click();
  }

  @action async addFiles(rawFiles: File[]) {
    this.dragOver = false;

    const files = Array.from(rawFiles).map((f) => SubmissionFile.fromRawFile(f));

    await Promise.all(
      files.map(async (file) => {
        this.args.onAdd(file);

        await file.parse();
        file.calculateDigest();
      }),
    );
  }
}
