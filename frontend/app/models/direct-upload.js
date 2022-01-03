import { tracked } from '@glimmer/tracking';

import { DirectUpload } from '@rails/activestorage';

const url = '/rails/active_storage/direct_uploads';

export default class _DirectUpload {
  @tracked uploads;
  @tracked currentUpload = null;

  constructor(files) {
    this.uploads = files.map(file => new Upload(file));
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

class Upload {
  @tracked file;
  @tracked isStarted    = false;
  @tracked uploadedSize = 0;

  constructor(file) {
    this.file = file;
  }

  perform() {
    // Since service switching is disabled on the server side, there is no need to send third and forth parameters.
    // See backend/config/initializers/active_storage_direct_uploads_controller_monkey.rb.
    const upload = new DirectUpload(this.file, url, null, null, {
      directUploadWillStoreFileWithXHR: (xhr) => {
        xhr.upload.addEventListener('loadstart', () => {
          this.isStarted = true;
        });

        xhr.upload.addEventListener('progress', ({loaded}) => {
          this.uploadedSize = loaded;
        });
      }
    });

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
