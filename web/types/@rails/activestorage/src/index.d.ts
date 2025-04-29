declare module '@rails/activestorage/src/blob_record' {
  export interface BlobRecordJSON {
    signed_id: string;
    filename: string;
    content_type: string;
    byte_size: number;
    checksum: string;
    direct_upload?: { url: string; headers: Record<string, string> };
    [key: string]: unknown;
  }

  export class BlobRecord {
    readonly file: File;
    readonly attributes: BlobRecordJSON;
    readonly directUploadData?: { url: string; headers: Record<string, string> };
    readonly xhr: XMLHttpRequest;

    constructor(file: File, checksum: string, url: string, headers?: Record<string, string>);

    create(callback: (error: XMLHttpRequest | null, blob?: BlobRecordJSON) => void): void;
    callback(error: XMLHttpRequest | null, blob?: BlobRecordJSON): void;
    requestDidLoad(event: ProgressEvent<XMLHttpRequest>): void;
    requestDidError(event: ProgressEvent<XMLHttpRequest>): void;
    toJSON(): BlobRecordJSON;
  }
}
