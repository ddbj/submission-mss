import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import { SubmissionFile } from 'mssform/models/submission-file';

export default class FileListComponent extends Component {
  allowedExtensions = SubmissionFile.allowedExtensions;
  fileInputElement  = null;

  @tracked dragOver = false;

  @action selectFiles() {
    this.fileInputElement.click();
  }

  @action async addFiles(files) {
    this.dragOver = false;

    const promises = Array.from(files).map((rawFile) => {
      const file = SubmissionFile.fromRawFile(rawFile);

      this.args.onAdd(file);

      return file.parse();
    });

    await Promise.all(promises);
  }
}
