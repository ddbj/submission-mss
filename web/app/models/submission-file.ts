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

  #discarded = new AbortController();

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

  // Stops the parsing and hashing still running for this file. Hashing a large
  // file takes a while, and there is nothing left to upload once the file has
  // been taken off the form.
  dispose() {
    this.#discarded.abort();
  }

  parse() {
    this.isParsing = true;

    return this.#runWorker(
      (this.constructor as SubmissionFileSubclass).parserURL,
      ([errs, payload]: [StructuredError[] | string | null, unknown]) => {
        if (typeof errs === 'string') {
          console.error(errs);

          this.errors.push({ severity: 'error', message: errs });

          throw new Error(errs);
        }

        if (errs) {
          this.errors.push(...errs);
        }

        if (payload) {
          this.parsedData = payload;
        }

        return this.parsedData;
      },
    ).finally(() => {
      this.isParsing = false;
    });
  }

  calculateDigest() {
    this.checksum = this.#runWorker('/workers/calculate-digest.js', ([err, digest]: [string | null, string]) => {
      if (err) {
        console.error(err);

        throw new Error(err);
      }

      return digest;
    });

    return this.checksum;
  }

  // Hands the file to a worker and settles with its single answer, or with the
  // `AbortError` the upload also uses if the file is discarded first. The
  // worker, if one was started at all, is terminated either way.
  async #runWorker<Message, Result>(url: string, handle: (message: Message) => Result) {
    const { signal } = this.#discarded;

    signal.throwIfAborted();

    let giveUp!: () => void;

    const message = await new Promise<Message>((resolve, reject) => {
      const worker = new Worker(url);

      giveUp = () => {
        worker.terminate();

        reject(signal.reason as Error);
      };

      signal.addEventListener('abort', giveUp, { once: true });

      worker.addEventListener('message', ({ data }: MessageEvent<Message>) => {
        worker.terminate();

        resolve(data);
      });

      worker.postMessage({ file: this.rawFile });
    }).finally(() => {
      signal.removeEventListener('abort', giveUp);
    });

    return handle(message);
  }
}

export class AnnotationFile extends SubmissionFile {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];
  static parserURL = '/workers/annotation-file-parser.js';

  fileType = 'annotation' as const;
}

export class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.fsa', '.seq.fa', '.fa', '.fna', '.seq'];
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

// Stops whatever is still running for the files being taken off the form.
// Extracted files are plain data, with no workers of their own.
export function discardFiles(files: SubmissionFileData[]) {
  for (const file of files) {
    if (file instanceof SubmissionFile) file.dispose();
  }
}
