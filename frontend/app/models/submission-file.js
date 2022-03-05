import { tracked } from '@glimmer/tracking';

export class SubmissionFile {
  static get allowedExtensions() {
    return [
      ...AnnotationFile.extensions,
      ...SequenceFile.extensions
    ];
  }

  static fromRawFile(file) {
    const klass = AnnotationFile.matchExtension(file.name) || SequenceFile.matchExtension(file.name) || UnsupportedFile;

    return new klass(file);
  }

  static matchExtension(filename) {
    return this.extensions.some(ext => filename.endsWith(ext)) && this;
  }

  @tracked isParsing = false;
  @tracked parsedData;
  @tracked errors = [];

  constructor(file) {
    const {name, type, lastModified} = file;

    this.rawFile = new File([file], name.replaceAll(/\s/g, '_'), {type, lastModified});

    if (!/^((?![\\/:*?"<>|. ]])[ -~])*$/.test(this.basename)) {
      this.errors = [...this.errors, {id: 'submission-file.invalid-filename'}];
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
    const {name, extname} = this;

    return extname ? name.slice(0, -extname.length) : name;
  }

  get extname() {
    return this.constructor.extensions.find(ext => this.name.endsWith(ext));
  }

  parse() {
    this.isParsing = true;

    return new Promise((resolve, reject) => {
      const worker = new Worker(this.constructor.workerURL);

      worker.addEventListener('message', ({data: [err, payload]}) => {
        if (err) {
          try {
            const {id, value} = JSON.parse(err);

            this.errors = [...this.errors, {id, value}];
          } catch (e) {
            console.error(e.message);

            this.errors = [...this.errors, err];
          }

          reject(err);
        } else {
          this.parsedData = payload;

          resolve(payload);
        }
      });

      worker.postMessage({file: this.rawFile});
    }).finally(() => {
      this.isParsing = false;
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
  static extensions = [];

  constructor() {
    super(...arguments);

    this.errors = [
      ...this.errors,
      {id: 'submission-file.unsupported-filetype'}
    ];
  }

  parse() {
    this.isParsing = false;
  }
}
