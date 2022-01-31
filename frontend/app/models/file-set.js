import { tracked } from '@glimmer/tracking';

export default class FileSet {
  allowedExtensions = [...AnnotationFile.extensions, ...SequenceFile.extensions];

  @tracked files = [];

  async add(rawFile) {
    const klass = [AnnotationFile, SequenceFile].find(klass => klass.matchExtension(rawFile.name));

    if (!klass) {
      throw new Error(`${rawFile.name}: アップロード可能なファイル拡張子は .ann, .fasta のいずれかです。`);
    }

    const file = new klass(rawFile);
    await file.parse();

    this.files = [...this.files, file];
  }

  remove(file) {
    this.files = this.files.filter(f => f !== file);
  }
}

class SubmissionFile {
  static matchExtension(filename) {
    return this.extensions.some(ext => filename.endsWith(ext));
  }

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
}

class AnnotationFile extends SubmissionFile {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];

  kind = 'annotation';

  async parse() {
  }
}

class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];

  kind = 'sequence';

  @tracked entriesCount;

  async parse() {
    const reader = this.rawFile.stream().pipeThrough(new TextDecoderStream()).pipeThrough(new LineStream()).getReader();

    let entriesCount = 0;

    for (let result = await reader.read(); !result.done; result = await reader.read()) {
      const line = result.value;

      if (line.startsWith('>')) {
        entriesCount++;
      }
    }

    this.entriesCount = entriesCount;
  }
}

class LineStream extends TransformStream {
  constructor() {
    super({
      start() {
        this.pending = '';
      },

      transform(chunk, controller) {
        if (!chunk) { return; }

        const buffer = this.pending + chunk;

        this.pending = buffer.replaceAll(/[^\n\r]*(?:\r\n|\n|\r)/g, (line) => {
          controller.enqueue(line);

          return '';
        });
      },

      flush(controller) {
        if (this.pending === '') { return; }

        controller.enqueue(this.pending);
      }
    });
  }
}
