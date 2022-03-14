import { tracked } from '@glimmer/tracking';

import { DirectUpload } from 'mssform/models/direct-upload';

export default class UploadFiles {
  @tracked uploads;
  @tracked currentUpload = null;

  constructor(files) {
    this.uploads = files.map(file => new UploadFile(file));
  }

  get totalSize() {
    return this.uploads.reduce((acc, {file}) => acc + file.size, 0);
  }

  get uploadedSize() {
    return this.uploads.reduce((acc, {uploadedSize}) => acc + uploadedSize, 0);
  }

  async perform() {
    const blobs = [];

    for (const upload of this.uploads) {
      this.currentUpload = upload;

      blobs.push(await upload.perform());
    }

    return blobs;
  }
}

class UploadFile {
  @tracked file;
  @tracked isStarted    = false;
  @tracked uploadedSize = 0;

  constructor(file) {
    this.file = file;
  }

  perform() {
    const upload = new DirectUpload(this.file.rawFile, '/api/direct_uploads', {
      directUploadWillStoreFileWithXHR: (xhr) => {
        xhr.upload.addEventListener('loadstart', () => {
          this.isStarted = true;
        });

        xhr.upload.addEventListener('progress', ({loaded}) => {
          this.uploadedSize = loaded;
        });
      }
    }, this.file.checksum);

    return new Promise((resolve, reject) => {
      upload.create((err, blob) => {
        if (err) {
          reject(err);
        } else {
          resolve(blob);
        }
      });
    });
  }
}
