import { tracked } from '@glimmer/tracking';

export default abstract class SubmissionFile<T = unknown> {
  static extensions: string[];
  static parserURL: string;

  static get allowedExtensions() {
    return [...AnnotationFile.extensions, ...SequenceFile.extensions];
  }

  static fromRawFile(file: File) {
    const klass = AnnotationFile.matchExtension(file.name)
      ? AnnotationFile
      : SequenceFile.matchExtension(file.name)
        ? SequenceFile
        : UnsupportedFile;

    return new klass(file);
  }

  static matchExtension(filename: string) {
    return this.extensions.some((ext) => filename.endsWith(ext));
  }

  abstract isAnnotation: boolean;
  abstract isSequence: boolean;

  @tracked isParsing = false;
  @tracked parsedData?: T;
  @tracked errors: ({ id: string; value?: unknown } | string)[] = [];

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
    const exts = (this.constructor as typeof SubmissionFile).extensions;

    return exts.find((ext) => this.name.endsWith(ext));
  }

  parse() {
    this.isParsing = true;

    return new Promise<T | void>((resolve, reject) => {
      const worker = new Worker((this.constructor as typeof SubmissionFile).parserURL);

      worker.addEventListener('message', ({ data: [err, payload] }: { data: [string, T] }) => {
        if (err) {
          try {
            const { id, value } = JSON.parse(err) as { id: string; value: unknown };

            this.errors = [...this.errors, { id, value }];

            resolve();
          } catch (e) {
            console.error(e);

            this.errors = [...this.errors, err];

            reject(new Error(err));
          }
        } else {
          this.parsedData = payload;

          resolve(payload);
        }

        worker.terminate();
      });

      worker.postMessage({ file: this.rawFile });
    }).finally(() => {
      this.isParsing = false;
    });
  }

  calculateDigest() {
    this.checksum = new Promise((resolve, reject) => {
      const worker = new Worker('/workers/calculate-digest.js');

      worker.addEventListener('message', ({ data: [err, digest] }: { data: [string, string] }) => {
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

export class AnnotationFile extends SubmissionFile<{
  contactPerson: {
    fullName: string;
    email: string;
    affiliation: string;
  };
  holdDate: string;
}> {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];
  static parserURL = '/workers/annotation-file-parser.js';

  isAnnotation = true;
  isSequence = false;
}

export class SequenceFile extends SubmissionFile<{ entriesCount: number }> {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];
  static parserURL = '/workers/sequence-file-parser.js';

  isAnnotation = false;
  isSequence = true;
}

export class UnsupportedFile extends SubmissionFile<void> {
  static extensions = [];

  isAnnotation = false;
  isSequence = false;

  constructor(file: File) {
    super(file);

    this.errors = [...this.errors, { id: 'submission-file.unsupported-filetype' }];
  }

  parse() {
    this.isParsing = false;

    return Promise.resolve();
  }
}
