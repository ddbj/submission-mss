import { tracked } from '@glimmer/tracking';

import { DirectUpload } from 'mssform/models/direct-upload';

import ENV from 'mssform/config/environment';

import type CurrentUserService from 'mssform/services/current-user';
import type SubmissionFile from 'mssform/models/submission-file';

export default class UploadFiles {
  @tracked uploads;
  @tracked currentUpload?: UploadFile;

  constructor(files: SubmissionFile[]) {
    this.uploads = files.map((file) => new UploadFile(file));
  }

  get totalSize() {
    return this.uploads.reduce((acc, { file }) => acc + file.size, 0);
  }

  get uploadedSize() {
    return this.uploads.reduce((acc, { uploadedSize }) => acc + uploadedSize, 0);
  }

  async perform(currentUser: CurrentUserService) {
    const blobs = [];

    for (const upload of this.uploads) {
      this.currentUpload = upload;

      blobs.push(await upload.perform(currentUser));
    }

    return blobs;
  }
}

class UploadFile {
  @tracked file;
  @tracked isStarted = false;
  @tracked uploadedSize = 0;

  constructor(file: SubmissionFile) {
    this.file = file;
  }

  perform(currentUser: CurrentUserService) {
    const upload = new DirectUpload(
      this.file.rawFile,
      `${ENV.apiURL}/direct_uploads`,
      {
        directUploadWillCreateBlobWithXHR: (xhr) => {
          xhr.setRequestHeader('Authorization', `Bearer ${currentUser.token}`);
        },

        directUploadWillStoreFileWithXHR: (xhr) => {
          xhr.upload.addEventListener('loadstart', () => {
            this.isStarted = true;
          });

          xhr.upload.addEventListener('progress', ({ loaded }) => {
            this.uploadedSize = loaded;
          });
        },
      },
      this.file.checksum!,
    );

    return upload.create();
  }
}
