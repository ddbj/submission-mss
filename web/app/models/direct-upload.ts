import { BlobRecord } from '@rails/activestorage/src/blob_record';
import { BlobUpload } from '@rails/activestorage/src/blob_upload';

import type { DirectUploadDelegate } from '@rails/activestorage';

export class DirectUpload {
  file: File;
  url: string;
  delegate: DirectUploadDelegate;
  checksum: Promise<string>;

  constructor(file: File, url: string, delegate: DirectUploadDelegate, checksum: Promise<string>) {
    this.file = file;
    this.url = url;
    this.delegate = delegate;
    this.checksum = checksum;
  }

  async create() {
    const blob = new BlobRecord(this.file, await this.checksum, this.url);
    blob.requestDidError = (event: ProgressEvent) => blob.callback(event.target as XMLHttpRequest);

    this.delegate.directUploadWillCreateBlobWithXHR!(blob.xhr);

    return new Promise<Record<string, unknown>>((resolve, reject) => {
      blob.create((error: string | null) => {
        if (error) {
          reject(new Error(error));
        } else {
          const upload = new BlobUpload(blob);
          upload.requestDidError = (event: ProgressEvent) => upload.callback(event.target as XMLHttpRequest);

          this.delegate.directUploadWillStoreFileWithXHR!(upload.xhr);

          upload.create((error: string | null) => {
            if (error) {
              reject(new Error(error));
            } else {
              resolve(blob.toJSON());
            }
          });
        }
      });
    });
  }
}
