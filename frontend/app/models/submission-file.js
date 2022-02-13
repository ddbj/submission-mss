import { tracked } from '@glimmer/tracking';

export class SubmissionFile {
  static get allowedExtensions() {
    return [
      ...AnnotationFile.extensions,
      ...SequenceFile.extensions
    ];
  }

  static createFromRawFile(file) {
    const klass = AnnotationFile.matchExtension(file.name) || SequenceFile.matchExtension(file.name) || UnsupportedFile;

    return new klass(file);
  }

  static matchExtension(filename) {
    return this.extensions.some(ext => filename.endsWith(ext)) && this;
  }

  @tracked parsedData;
  @tracked error;

  constructor(rawFile) {
    this.rawFile = rawFile;
  }

  get isValid() {
    return Boolean(this.parsedData);
  }

  get isError() {
    return Boolean(this.error);
  }

  get isParsed() {
    return this.isValid || this.isError;
  }

  get name() {
    return this.rawFile.name;
  }

  get size() {
    return this.rawFile.size;
  }

  get basename() {
    const {name}    = this.rawFile;
    const {extname} = this;

    return extname ? name.slice(0, -extname.length) : name;
  }

  get extname() {
    const {name} = this.rawFile;

    return this.constructor.extensions.find(ext => name.endsWith(ext));
  }

  parse() {
    return new Promise((resolve, reject) => {
      const worker = new Worker(this.constructor.workerURL);

      worker.addEventListener('message', ({data: [err, payload]}) => {
        if (err) {
          this.error = err;

          reject(err);
        } else {
          this.parsedData = payload;

          resolve(payload);
        }
      });

      worker.postMessage({file: this.rawFile});
    });
  }
}

export class AnnotationFile extends SubmissionFile {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];
  static workerURL  = '/workers/annotation-file-parser.js';

  isAnnotation = true;
}

export class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];
  static workerURL  = '/workers/sequence-file-parser.js';

  isSequence = true;
}

export class UnsupportedFile extends SubmissionFile {
  error = '登録ファイルの拡張子は .ann, .fasta のいずれかです。';

  parse() {
    // do nothing
  }
}
