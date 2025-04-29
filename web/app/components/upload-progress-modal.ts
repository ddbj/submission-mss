import Component from '@glimmer/component';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { Modal } from 'bootstrap';

import UploadFiles from 'mssform/models/upload-files';

import type CurrentUserService from 'mssform/services/current-user';
import type SubmissionFile from 'mssform/models/submission-file';

export default class UploadProgressModalComponent extends Component {
  @service declare currentUser: CurrentUserService;

  @tracked uploadFiles?: UploadFiles;

  modal?: Modal;

  setModal = modifier((element) => {
    this.modal = new Modal(element);
  });

  @action hide() {
    this.modal!.hide();
  }

  async performUpload(files: SubmissionFile[]) {
    if (!files.length) return [];

    this.uploadFiles = new UploadFiles(files);
    this.modal!.show();

    let blobs;

    try {
      blobs = await this.uploadFiles.perform(this.currentUser);
    } finally {
      this.modal!.hide();
    }

    return blobs;
  }

  percentage(x?: number, y?: number) {
    if (!x || !y) return 0;

    return Math.floor((x / y) * 100);
  }
}
