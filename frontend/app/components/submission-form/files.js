import Component from '@glimmer/component';

import { NotFoundError } from '@ember-data/adapter/error';
import { action } from '@ember/object';
import { dropTask } from 'ember-concurrency';
import { service } from '@ember/service';

import { handleAppAuthHTTPError, handleAdapterError } from 'mssform/utils/error-handler';

export default class SubmissionFormFilesComponent extends Component {
  @service store;
  @service session;

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
    const {uploadVia} = this.args.model;
    const {files}     = this.args.state;

    if (!uploadVia)    { return false; }
    if (!files.length) { return false; }

    for (const file of files) {
      if (file.isParsing || file.errors.length) { return false; }
    }

    for (const errs of this.crossoverErrors.values()) {
      if (errs.length) { return false; }
    }

    return true;
  }

  @action setUploadVia(val) {
    const {model, state} = this.args;

    model.uploadVia    = val;
    model.extractionId = null;
    state.files        = [];
  }

  @action onExtractProgress({id, files}) {
    const {model, state} = this.args;

    model.extractionId = id;
    state.files        = files;
  }

  @action addFile(file) {
    const {state} = this.args;

    state.files = [...state.files, file];
  }

  @action removeFile(file) {
    const {state} = this.args;

    state.files = state.files.filter(f => f !== file);
  }

  @dropTask *goNext() {
    try {
      yield this.session.renewToken();
    } catch (e) {
      handleAppAuthHTTPError(e, this.session);
      return;
    }

    try {
      yield this.fillDataFromLastSubmission();
    } catch (e) {
      if (e instanceof NotFoundError) {
        // do nothing
      } else {
        handleAdapterError(e, this.session);
        return;
      }
    }

    this.fillDataFromSubmissionFiles();

    this.args.nav.goNext();
  }

  async fillDataFromLastSubmission() {
    const last = await this.store.queryRecord('submission', {lastSubmitted: true});

    if (!last) { return; }

    const {model} = this.args;

    model.contactPerson.email       = last.contactPerson.email;
    model.contactPerson.fullName    = last.contactPerson.fullName;
    model.contactPerson.affiliation = last.contactPerson.affiliation;

    if (model.otherPeople.length === 0) {
      for (const person of last.otherPeople.slice()) {
        model.otherPeople.createRecord({
          email:       person.email,
          fullName:    person.fullName,
          affiliation: person.affiliation
        });
      }
    }

    if (!model.sequencer) {
      model.sequencer = last.sequencer;
    }

    if (!model.emailLanguage) {
      model.emailLanguage = last.emailLanguage;
    }
  }

  fillDataFromSubmissionFiles() {
    const {state, model} = this.args;
    const {files}        = state;

    const {contactPerson, holdDate} = files.find(({isAnnotation}) => isAnnotation).parsedData;

    Object.assign(model.contactPerson, contactPerson || {});

    model.holdDate = holdDate;

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
        errors.get(file).push({id: 'submission-form.files.errors.no-annotation'});
      }
    }

    if (annotations.length > 1) {
      for (const file of annotations) {
        errors.get(file).push({id: 'submission-form.files.errors.duplicate-annotations'});
      }
    }

    if (!sequences.length) {
      for (const file of annotations) {
        errors.get(file).push({id: 'submission-form.files.errors.no-sequence'});
      }
    }

    if (sequences.length > 1) {
      for (const file of sequences) {
        errors.get(file).push({id: 'submission-form.files.errors.duplicate-sequences'});
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
      errors.get(file).push({id: 'submission-form.files.errors.different-contact-person'});
    }
  }

  if (holdDateSet.size > 1) {
    for (const file of files) {
      errors.get(file).push({id: 'submission-form.files.errors.different-hold-date'});
    }
  }
}
