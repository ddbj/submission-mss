import Component from '@glimmer/component';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import { SubmissionFile } from 'mssform/models/submission-file';

export default class FileListComponent extends Component {
  allowedExtensions = SubmissionFile.allowedExtensions;
  fileInputElement  = null;

  @tracked dragOver = false;

  setFileInputElement = modifier((element) => {
    this.fileInputElement = element;
  });

  @action selectFiles() {
    this.fileInputElement.click();
  }

  @action addFiles(rawFiles) {
    this.dragOver = false;

    const files = Array.from(rawFiles).map(SubmissionFile.fromRawFile);

    for (const file of files) {
      this.args.onAdd(file);

      file.parse().then(() => {
        file.calculateDigest();
      });
    }
  }
}
