import { setOwner } from '@ember/application';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class FileSet {
  allowedExtensions = [...AnnotationFile.extensions, ...SequenceFile.extensions];

  @tracked files = [];

  owner;

  constructor({owner}) {
    this.owner = owner;
  }

  get isEmpty() {
    return this.files.length === 0;
  }

  get annotationFiles() {
    return this.files.filter(({type}) => type === 'annotation');
  }

  get sequenceFiles() {
    return this.files.filter(({type}) => type === 'sequence');
  }

  async add(rawFile) {
    const klass = [AnnotationFile, SequenceFile].find(klass => klass.matchExtension(rawFile.name));

    if (!klass) {
      throw new Error(`${rawFile.name}: アップロード可能なファイル拡張子は .ann, .fasta のいずれかです。`);
    }

    const file = new klass(rawFile, {owner: this.owner});

    this.files = [...this.files, file];

    await file.parse();
  }

  remove(file) {
    this.files = this.files.filter(f => f !== file);
  }
}

class SubmissionFile {
  static matchExtension(filename) {
    return this.extensions.some(ext => filename.endsWith(ext));
  }

  @service fileParser;

  @tracked parsedData;

  constructor(rawFile, {owner}) {
    setOwner(this, owner);

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

  async parse() {
    this.parsedData = await this.fileParser.parse(this.type, this.rawFile);
  }
}

class AnnotationFile extends SubmissionFile {
  static extensions = ['.ann', '.annt.tsv', '.ann.txt'];

  type = 'annotation';
}

class SequenceFile extends SubmissionFile {
  static extensions = ['.fasta', '.seq.fa', '.fa', '.fna', '.seq'];

  type = 'sequence';
}
