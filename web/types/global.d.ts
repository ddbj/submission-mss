// Types for compiled templates
declare module 'mssform/templates/*' {
  import { TemplateFactory } from 'ember-cli-htmlbars';

  const tmpl: TemplateFactory;
  export default tmpl;
}

declare module '@rails/activestorage/src/blob_record' {
  export class BlobRecord {
    file: File;
    xhr: XMLHttpRequest;
    directUploadData: { headers: Record<string, string>; url: string };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    callback: (...args: any[]) => void;
    requestDidError: (event: ProgressEvent) => void;

    constructor(file: File, checksum: string, url: string);

    create(callback: (error: string | null, blob?: Record<string, unknown>) => void): void;
    toJSON(): Record<string, unknown>;
  }
}

declare module '@rails/activestorage/src/blob_upload' {
  export class BlobUpload {
    xhr: XMLHttpRequest;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    callback: (...args: any[]) => void;
    requestDidError: (event: ProgressEvent) => void;

    constructor(blob: { file: File; directUploadData: { headers: Record<string, string>; url: string } });

    create(callback: (error: string | null) => void): void;
  }
}
