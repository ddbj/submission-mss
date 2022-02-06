import { tracked } from '@glimmer/tracking';

class SubmissionFile {
  static matchExtension(filename) {
    return this.extensions.some(ext => filename.endsWith(ext));
  }

  @tracked parsedData;

  constructor(rawFile) {
    this.rawFile = rawFile;
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
      const worker = new Worker(`/workers/${this.type}-file-parser.js`);

      worker.addEventListener('message', ({data}) => {
        this.parsedData = data;

        resolve(data);
      });

      worker.addEventListener('error', (e) => {
        reject(e);
      });

      worker.postMessage({file: this.rawFile});
    });
  }
}

export class AnnotationFile extends SubmissionFile {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];

  type = 'annotation';
}

export class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];

  type = 'sequence';
}
