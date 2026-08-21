import { tracked } from '@glimmer/tracking';

import { DirectUpload } from 'mssform/models/direct-upload';
import type { SubmissionFile } from 'mssform/models/submission-file';

import ENV from 'mssform/config/environment';

import type CurrentUserService from 'mssform/services/current-user';

export default class UploadFiles {
  @tracked uploads: UploadFile[];
  @tracked currentUpload: UploadFile | null = null;

  constructor(files: SubmissionFile[]) {
    this.uploads = files.map((file) => new UploadFile(file));
  }

  get totalSize() {
    return this.uploads.reduce((acc, { file }) => acc + file.size, 0);
  }

  get uploadedSize() {
    return this.uploads.reduce((acc, { uploadedSize }) => acc + uploadedSize, 0);
  }

  async perform(currentUser: CurrentUserService, signal: AbortSignal) {
    const blobs = [];

    for (const upload of this.uploads) {
      this.currentUpload = upload;

      blobs.push(await upload.perform(currentUser, signal));
    }

    return blobs;
  }
}

class UploadFile {
  @tracked file: SubmissionFile;
  @tracked isStarted = false;
  @tracked uploadedSize = 0;

  constructor(file: SubmissionFile) {
    this.file = file;
  }

  perform(currentUser: CurrentUserService, signal: AbortSignal) {
    const upload = new DirectUpload(
      this.file.rawFile,
      ENV.directUploadURL,
      {
        // Not routed through the request manager, so the session cookie and
        // the token that says the write came from us have to be asked for here.
        directUploadWillCreateBlobWithXHR: (xhr: XMLHttpRequest) => {
          xhr.withCredentials = true;
          xhr.setRequestHeader('X-CSRF-Token', currentUser.csrfToken!);
        },

        directUploadWillStoreFileWithXHR: (xhr: XMLHttpRequest) => {
          xhr.upload.addEventListener('loadstart', () => {
            this.isStarted = true;
          });

          xhr.upload.addEventListener('progress', ({ loaded }) => {
            this.uploadedSize = loaded;
          });
        },
      },
      this.file.checksum!,
      signal,
    );

    return upload.create();
  }
}
