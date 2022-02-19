import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormFilesComponent extends Component {
  get crossoverErrors() {
    const {files} = this.args.state;
    const errors  = new Map();

    for (const file of files) {
      errors.set(file, []);
    }

    validatePair(errors, files);
    validateSameness(errors, files);

    return errors;
  }

  get isNextButtonEnabled() {
    const {uploadType, files} = this.args.state;

    if (!uploadType)           { return false; }
    if (uploadType === 'none') { return true;  }
    if (!files.length)         { return false; }

    for (const file of files) {
      if (file.isParsing || file.errors.length) { return false; }
    }

    for (const errors of this.crossoverErrors.values()) {
      if (errors.length) { return false; }
    }

    return true;
  }

  @action setUploadType(val) {
    const {model, state} = this.args;

    state.uploadType = val;
    model.dfast      = val === 'dfast';

    if (val === 'none') {
      state.files = [];
    }
  }

  @action addFile(file) {
    const {state} = this.args;

    state.files = [...state.files, file];
  }

  @action removeFile(file) {
    const {state} = this.args;

    state.files = state.files.filter(f => f !== file);
  }

  @action goNext() {
    this.setParsedData();

    this.args.nav.goNext();
  }

  setParsedData() {
    const {state, model}  = this.args;
    const {uploadType, files} = state;

    if (uploadType === 'none') { return; }

    const {contactPerson, holdDate} = files.find(({isAnnotation}) => isAnnotation).parsedData;

    Object.assign(model.contactPerson, contactPerson || {});
    state.isContactPersonReadonly = !!contactPerson;

    model.holdDate           = holdDate;
    state.releaseImmediately = !holdDate;

    model.entriesCount = files.filter(({isSequence}) => isSequence).reduce((acc, file) => {
      return acc + file.parsedData.entriesCount;
    }, 0);
  }
}

function validatePair(errors, files) {
  const grouped = files.reduce((map, file) => {
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
        errors.get(file).push('対応するアノテーションファイルがありません。');
      }
    }

    if (annotations.length > 1) {
      for (const file of annotations) {
        errors.get(file).push('同名のアノテーションファイルが複数あります。');
      }
    }

    if (!sequences.length) {
      for (const file of annotations) {
        errors.get(file).push('対応する配列ファイルがありません。');
      }
    }

    if (sequences.length > 1) {
      for (const file of sequences) {
        errors.get(file).push('同名の配列ファイルが複数あります。');
      }
    }
  }
}

function validateSameness(errors, files) {
  files = files.filter(({isAnnotation, isParseSucceeded}) => isAnnotation && isParseSucceeded);

  if (!files.length) { return []; }

  const contactPersonSet = new Set();
  const holdDateSet      = new Set();

  for (const file of files) {
    const {contactPerson, holdDate} = file.parsedData;

    contactPersonSet.add(JSON.stringify(contactPerson));
    holdDateSet.add(holdDate);
  }

  if (contactPersonSet.size > 1) {
    for (const file of files) {
      errors.get(file).push('コンタクトパーソンはすべてのアノテーションファイルで同一でなければなりません。');
    }
  }

  if (holdDateSet.size > 1) {
    for (const file of files) {
      errors.get(file).push('公開予定日はすべてのアノテーションファイルで同一でなければなりません。');
    }
  }
}
