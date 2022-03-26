import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { UploadError } from 'mssform/models/direct-upload';

import Modal from 'bootstrap/js/src/modal';

import UploadFiles from 'mssform/models/upload-files';

export default class UploadProgressModalComponent extends Component {
  @service session;

  @tracked uploadFiles;

  @service session;

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

    let blobs;

    try {
      blobs = await this.uploadFiles.perform(this.session);
    } catch(e) {
      if (e instanceof UploadError)  {
        if (e.status === 401) {
          alert('Your session has been expired. Please re-login.');

          this.session.invalidate();
        } else if (e.status >= 500) {
          alert('Upload failed for some reason. Please retry in a few minutes.');

          return;
        }
      }

      throw e;
    } finally {
      this.modal.hide();
    }

    return blobs;
  }
}
