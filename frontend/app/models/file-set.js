import { tracked } from '@glimmer/tracking';

import { AnnotationFile, SequenceFile } from 'mssform/models/submission-file';

export default class FileSet {
  allowedExtensions = [...AnnotationFile.extensions, ...SequenceFile.extensions];

  @tracked files = [];

  get isEmpty() {
    return this.files.length === 0;
  }

  get everyValid() {
    return this.files.every(({isValid}) => isValid);
  }

  async add(rawFile) {
    const klass = [AnnotationFile, SequenceFile].find(klass => klass.matchExtension(rawFile.name));

    if (!klass) {
      throw new Error(`${rawFile.name}: アップロード可能なファイル拡張子は .ann, .fasta のいずれかです。`);
    }

    const file = new klass(rawFile);

    this.files = [...this.files, file];

    await file.parse();
  }

  remove(file) {
    this.files = this.files.filter(f => f !== file);
  }
}
