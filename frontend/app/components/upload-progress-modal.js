import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import Modal from 'bootstrap/js/src/modal';

import UploadFiles from 'mssform/models/upload-files';

export default class UploadProgressModalComponent extends Component {
  @tracked uploadFiles;

  @action setModal(element) {
    this.modal = new Modal(element);
  }

  @action hide() {
    this.modal.hide();
  }

  async performUpload(files) {
    if (!files.length) { return []; }

    this.uploadFiles = new UploadFiles(files);

    this.modal.show();
    const blobs = await this.uploadFiles.perform();
    this.modal.hide();

    return blobs;
  }
}
