import { tracked } from '@glimmer/tracking';

import { SubmissionFile } from 'mssform/models/submission-file';

export default class FileSet {
  allowedExtensions = SubmissionFile.allowedExtensions;

  @tracked files = [];

  add(file) {
    file.fileSet = this;

    this.files = [...this.files, file];
  }

  remove(file) {
    this.files = this.files.filter(f => f !== file);
  }

  get globalErrors() {
    return this.annotationFileErrors;
  }

  get annotationFileErrors() {
    const files = this.files.filter(({isAnnotation, isParseSucceeded}) => isAnnotation && isParseSucceeded);

    if (!files.length) { return []; }

    const contactPersonSet = new Set();
    const holdDateSet      = new Set();

    for (const file of files) {
      const {contactPerson, holdDate} = file.parsedData;

      contactPersonSet.add(JSON.stringify(contactPerson));
      holdDateSet.add(holdDate);
    }

    const errors = [];

    if (contactPersonSet.size > 1) {
      errors.push('コンタクトパーソンはすべてのアノテーションファイルで同一でなければなりません。');
    }

    if (holdDateSet.size > 1) {
      errors.push('公開予定日はすべてのアノテーションファイルで同一でなければなりません。');
    }

    return errors;
  }

  get perFileErrors() {
    const errors = new Map();

    for (const file of this.files) {
      errors.set(file, []);
    }

    const grouped = this.files.reduce((map, file) => {
      const val = map.has(file.basename) ? [...map.get(file.basename), file] : [file];

      return map.set(file.basename, val);
    }, new Map());

    for (const files of grouped.values()) {
      const [annotations, sequences] = files.reduce(([ann, seq], file) => {
        return [
          file.isAnnotation ? [...ann, file] : ann,
          file.isSequence   ? [...seq, file] : seq
        ];
      }, [[], []]);

      if (!annotations.length) {
        for (const file of sequences) {
          errors.set(file, [...errors.get(file), '対応するアノテーションファイルがありません。']);
        }
      }

      if (annotations.length > 1) {
        for (const file of annotations) {
          errors.set(file, [...errors.get(file), '同名のアノテーションファイルが複数あります。']);
        }
      }

      if (!sequences.length) {
        for (const file of annotations) {
          errors.set(file, [...errors.get(file), '対応する配列ファイルがありません。']);
        }
      }

      if (sequences.length > 1) {
        for (const file of sequences) {
          errors.set(file, [...errors.get(file), '同名の配列ファイルが複数あります。']);
        }
      }
    }

    return errors;
  }
}
