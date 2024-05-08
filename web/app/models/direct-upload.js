import { BlobRecord } from '@rails/activestorage/src/blob_record';
import { BlobUpload } from '@rails/activestorage/src/blob_upload';

export class DirectUpload {
  constructor(file, url, delegate, checksum) {
    this.file     = file;
    this.url      = url;
    this.delegate = delegate;
    this.checksum = checksum;
  }

  async create() {
    const blob = new BlobRecord(this.file, await this.checksum, this.url);
    blob.requestDidError = (event) => blob.callback(event.target);

    await this.delegate.directUploadWillCreateBlobWithXHR(blob.xhr);

    return new Promise((resolve, reject) => {
      blob.create((error) => {
        if (error) {
          reject(error);
        } else {
          const upload = new BlobUpload(blob);
          upload.requestDidError = (event) => upload.callback(event.target);

          this.delegate.directUploadWillStoreFileWithXHR(upload.xhr);

          upload.create((error) => {
            if (error) {
              reject(error);
            } else {
              resolve(blob.toJSON());
            }
          });
        }
      });
    });
  }
}
