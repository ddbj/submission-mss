import { tracked } from '@glimmer/tracking';
import { trackedArray } from '@ember/reactive/collections';

import type { components } from 'schema/openapi';

export type ParsedData = components['schemas']['ParsedData'];

interface StructuredError {
  severity: 'error' | 'warning';
  id: string;
  value?: string | null;
  message?: never;
}

interface UnstructuredError {
  severity: 'error' | 'warning';
  message: string;
  id?: never;
}

export type SubmissionError = StructuredError | UnstructuredError;

export interface SubmissionFileData {
  name: string;
  size: number;
  basename: string;
  fileType?: 'annotation' | 'sequence';
  isParsing: boolean;
  parsedData?: ParsedData | null;
  isParseSucceeded: boolean;
  errors: SubmissionError[] | null;
  jobId?: string;
}

type SubmissionFileSubclass = typeof AnnotationFile | typeof SequenceFile | typeof UnsupportedFile;

export class SubmissionFile implements SubmissionFileData {
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
  errors: SubmissionError[] = trackedArray();

  fileType?: 'annotation' | 'sequence';
  jobId?: string;

  rawFile: File;
  checksum?: Promise<string>;

  constructor(file: File) {
    const { name, type, lastModified } = file;

    this.rawFile = new File([file], name.replaceAll(/\s/g, '_'), { type, lastModified });

    if (!/^((?![\\/:*?"<>|. ]])[ -~])*$/.test(this.basename)) {
      this.errors.push({
        severity: 'error',
        id: 'submission-file.invalid-filename',
      });
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

      worker.addEventListener(
        'message',
        ({ data: [errs, payload] }: MessageEvent<[StructuredError[] | string | null, unknown]>) => {
          if (typeof errs === 'string') {
            console.error(errs);

            this.errors.push({ severity: 'error', message: errs });

            reject(new Error(errs));
          } else {
            if (errs) {
              this.errors.push(...errs);
            }

            if (payload) {
              this.parsedData = payload as ParsedData;
            }

            resolve(this.parsedData);
          }

          worker.terminate();
        },
      );

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

  fileType = 'annotation' as const;
}

export class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];
  static parserURL = '/workers/sequence-file-parser.js';

  fileType = 'sequence' as const;
}

export class UnsupportedFile extends SubmissionFile {
  static extensions: string[] = [];

  constructor(file: File) {
    super(file);

    this.errors.push({
      severity: 'error',
      id: 'submission-file.unsupported-filetype',
    });
  }

  parse() {
    this.isParsing = false;

    return Promise.resolve(undefined);
  }
}
