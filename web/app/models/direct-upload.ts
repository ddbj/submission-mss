import { BlobRecord } from '@rails/activestorage/src/blob_record';
import { BlobUpload } from '@rails/activestorage/src/blob_upload';

import type { DirectUploadDelegate } from '@rails/activestorage';

export class DirectUpload {
  file: File;
  url: string;
  delegate: DirectUploadDelegate;
  checksum: Promise<string>;
  signal: AbortSignal;

  constructor(file: File, url: string, delegate: DirectUploadDelegate, checksum: Promise<string>, signal: AbortSignal) {
    this.file = file;
    this.url = url;
    this.delegate = delegate;
    this.checksum = checksum;
    this.signal = signal;
  }

  async create() {
    const { signal } = this;
    const checksum = await this.checksum;

    signal.throwIfAborted();

    const blob = new BlobRecord(this.file, checksum, this.url);

    this.delegate.directUploadWillCreateBlobWithXHR!(blob.xhr);

    let inFlight = blob.xhr;
    let abortInFlight!: () => void;

    return new Promise<Record<string, unknown>>((resolve, reject) => {
      // Active Storage listens for `load` and `error` only, so an aborted
      // request would leave this promise pending: reject it here instead, with
      // the same `AbortError` the fetch-based extractors raise.
      abortInFlight = () => {
        inFlight.abort();

        reject(signal.reason as Error);
      };

      signal.addEventListener('abort', abortInFlight, { once: true });

      blob.create((error: string | null) => {
        if (error) {
          reject(new Error(error));
        } else {
          const upload = new BlobUpload(blob);

          inFlight = upload.xhr;

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
    }).finally(() => {
      // Nothing is left to abort, and a finished request must not be touched
      // when a later file is abandoned.
      signal.removeEventListener('abort', abortInFlight);
    });
  }
}
