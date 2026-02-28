import { tracked } from '@glimmer/tracking';

import type { components } from 'schema/openapi';

export interface SubmissionError {
  id?: string;
  message?: string;
  value?: unknown;
}

export type ParsedData = components['schemas']['ParsedData'];

type SubmissionFileSubclass = typeof AnnotationFile | typeof SequenceFile | typeof UnsupportedFile;

export class SubmissionFile {
  static get allowedExtensions() {
    return [...AnnotationFile.extensions, ...SequenceFile.extensions];
  }

  static fromRawFile(file: File) {
    const klass = AnnotationFile.matchExtension(file.name) || SequenceFile.matchExtension(file.name) || UnsupportedFile;

    return new klass(file);
  }

  static extensions: string[];
  static parserURL: string;

  static matchExtension(filename: string) {
    return this.extensions.some((ext) => filename.endsWith(ext)) && this;
  }

  @tracked isParsing = false;
  @tracked parsedData?: ParsedData;
  @tracked errors: SubmissionError[] = [];

  isAnnotation?: boolean;
  isSequence?: boolean;
  jobId?: string;

  rawFile: File;
  checksum?: Promise<string>;

  constructor(file: File) {
    const { name, type, lastModified } = file;

    this.rawFile = new File([file], name.replaceAll(/\s/g, '_'), { type, lastModified });

    if (!/^((?![\\/:*?"<>|. ]])[ -~])*$/.test(this.basename)) {
      this.errors = [...this.errors, { id: 'submission-file.invalid-filename' }];
    }
  }

  get isParseSucceeded() {
    return Boolean(this.parsedData);
  }

  get name() {
    return this.rawFile.name;
  }

  get size() {
    return this.rawFile.size;
  }

  get basename() {
    const { name, extname } = this;

    return extname ? name.slice(0, -extname.length) : name;
  }

  get extname() {
    return (this.constructor as SubmissionFileSubclass).extensions.find((ext) => this.name.endsWith(ext));
  }

  parse() {
    this.isParsing = true;

    return new Promise<ParsedData | undefined>((resolve, reject) => {
      const worker = new Worker((this.constructor as SubmissionFileSubclass).parserURL);

      worker.addEventListener('message', ({ data: [err, payload] }: MessageEvent<[string | null, unknown]>) => {
        if (err) {
          try {
            const { id, value } = JSON.parse(err) as SubmissionError;

            this.errors = [...this.errors, { id, value }];

            resolve(undefined);
          } catch (e) {
            console.error(e);

            this.errors = [...this.errors, { message: err }];

            reject(new Error(err));
          }
        } else {
          this.parsedData = payload as ParsedData;

          resolve(this.parsedData);
        }

        worker.terminate();
      });

      worker.postMessage({ file: this.rawFile });
    }).finally(() => {
      this.isParsing = false;
    });
  }

  calculateDigest() {
    this.checksum = new Promise<string>((resolve, reject) => {
      const worker = new Worker('/workers/calculate-digest.js');

      worker.addEventListener('message', ({ data: [err, digest] }: MessageEvent<[string | null, string]>) => {
        if (err) {
          console.error(err);

          reject(new Error(err));
        } else {
          resolve(digest);
        }

        worker.terminate();
      });

      worker.postMessage({ file: this.rawFile });
    });
  }
}

export class AnnotationFile extends SubmissionFile {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];
  static parserURL = '/workers/annotation-file-parser.js';

  isAnnotation = true;
}

export class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];
  static parserURL = '/workers/sequence-file-parser.js';

  isSequence = true;
}

export class UnsupportedFile extends SubmissionFile {
  static extensions: string[] = [];

  constructor(file: File) {
    super(file);

    this.errors = [...this.errors, { id: 'submission-file.unsupported-filetype' }];
  }

  parse() {
    this.isParsing = false;

    return Promise.resolve(undefined);
  }
}
