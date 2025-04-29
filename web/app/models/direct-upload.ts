import { BlobRecord } from '@rails/activestorage/src/blob_record';
import { BlobUpload } from '@rails/activestorage/src/blob_upload';

import type { Blob, DirectUploadDelegate } from '@rails/activestorage';

export class DirectUpload {
  file;
  url;
  delegate;
  checksum;

  constructor(file: File, url: string, delegate: DirectUploadDelegate, checksum: Promise<string>) {
    this.file = file;
    this.url = url;
    this.delegate = delegate;
    this.checksum = checksum;
  }

  async create(): Promise<Blob> {
    const blob = new BlobRecord(this.file, await this.checksum, this.url);

    this.delegate.directUploadWillCreateBlobWithXHR?.(blob.xhr);

    return new Promise((resolve, reject) => {
      blob.create((error) => {
        if (error) {
          // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
          reject(error);
        } else {
          // @ts-expect-error original code is not typed
          const upload = new BlobUpload(blob);

          this.delegate.directUploadWillStoreFileWithXHR?.(upload.xhr);

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
