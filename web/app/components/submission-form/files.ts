import Component from '@glimmer/component';

import { action } from '@ember/object';
import { dropTask } from 'ember-concurrency';
import { service } from '@ember/service';

import OtherPerson from 'mssform/models/other-person';
import { AnnotationFile, SequenceFile } from 'mssform/models/submission-file';

import type RequestService from 'mssform/services/request';
import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';
import type SubmissionFile from 'mssform/models/submission-file';

interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

type Errors = Map<SubmissionFile, { id: string }[]>;

export default class SubmissionFormFilesComponent extends Component<Signature> {
  @service declare request: RequestService;

  get crossoverErrors() {
    const { files } = this.args.state;
    const errors: Errors = new Map();

    for (const file of files) {
      errors.set(file, []);
    }

    validatePair(errors, files);
    validateSameness(errors, files);

    return errors;
  }

  get isNextButtonEnabled() {
    const { uploadVia } = this.args.model;
    const { files } = this.args.state;

    if (!uploadVia) return false;
    if (!files.length) return false;

    for (const file of files) {
      if (file.isParsing || file.errors.length) return false;
    }

    for (const errs of this.crossoverErrors.values()) {
      if (errs.length) return false;
    }

    return true;
  }

  @action setUploadVia(val: Submission['uploadVia']) {
    const { model, state } = this.args;

    model.uploadVia = val;
    model.extractionId = undefined;
    state.files = [];
  }

  @action onExtractProgress({ id, files }: { id: string; files: SubmissionFile[] }) {
    const { model, state } = this.args;

    model.extractionId = id;
    state.files = files;
  }

  @action addFile(file: SubmissionFile) {
    const { state } = this.args;

    state.files = [...state.files, file];
  }

  @action removeFile(file: SubmissionFile) {
    const { state } = this.args;

    state.files = state.files.filter((f) => f !== file);
  }

  @dropTask *goNext() {
    yield this.fillDataFromLastSubmission();
    this.fillDataFromSubmissionFiles();

    this.args.nav.goNext();
  }

  async fillDataFromLastSubmission() {
    let last;

    try {
      const res = await this.request.fetch('/submissions/last_submitted');

      last = (
        (await res.json()) as {
          submission: {
            sequencer: Submission['sequencer'];
            email_language: Submission['emailLanguage'];

            contact_person: {
              email: string;
              full_name: string;
              affiliation: string;
            };

            other_people: {
              email: string;
              full_name: string;
            }[];
          };
        }
      ).submission;
    } catch {
      // do nothing
    }

    if (!last) return;

    const { model } = this.args;

    model.contactPerson.email = last.contact_person.email;
    model.contactPerson.fullName = last.contact_person.full_name;
    model.contactPerson.affiliation = last.contact_person.affiliation;

    model.otherPeople = last.other_people.map(({ email, full_name }) => {
      const person = new OtherPerson();

      return Object.assign(person, { email, fullName: full_name });
    });

    if (!model.sequencer) {
      model.sequencer = last.sequencer;
    }

    if (!model.emailLanguage) {
      model.emailLanguage = last.email_language;
    }
  }

  fillDataFromSubmissionFiles() {
    const { state, model } = this.args;
    const { files } = state;

    const { contactPerson, holdDate } = files.find((file) => file instanceof AnnotationFile)!.parsedData!;

    Object.assign(model.contactPerson, contactPerson || {});

    model.holdDate = holdDate;

    model.entriesCount = files
      .filter((file) => file instanceof SequenceFile)
      .reduce((acc, file) => {
        return acc + file.parsedData!.entriesCount;
      }, 0);
  }
}

function validatePair(errors: Errors, files: SubmissionFile[]) {
  const grouped = files.reduce((map, file) => {
    const val = map.has(file.basename) ? [...map.get(file.basename)!, file] : [file];

    return map.set(file.basename, val);
  }, new Map<string, SubmissionFile[]>());

  for (const files of grouped.values()) {
    const [annotations, sequences] = files.reduce(
      ([ann, seq], file) => {
        return [
          file instanceof AnnotationFile ? [...ann, file] : ann,
          file instanceof SequenceFile ? [...seq, file] : seq,
        ];
      },
      [[] as AnnotationFile[], [] as SequenceFile[]],
    );

    if (!annotations.length) {
      for (const file of sequences) {
        errors.get(file)!.push({ id: 'submission-form.files.errors.no-annotation' });
      }
    }

    if (annotations.length > 1) {
      for (const file of annotations) {
        errors.get(file)!.push({ id: 'submission-form.files.errors.duplicate-annotations' });
      }
    }

    if (!sequences.length) {
      for (const file of annotations) {
        errors.get(file)!.push({ id: 'submission-form.files.errors.no-sequence' });
      }
    }

    if (sequences.length > 1) {
      for (const file of sequences) {
        errors.get(file)!.push({ id: 'submission-form.files.errors.duplicate-sequences' });
      }
    }
  }
}

function validateSameness(errors: Errors, files: SubmissionFile[]) {
  const _files = files.filter(
    (file): file is AnnotationFile => file instanceof AnnotationFile && file.isParseSucceeded,
  );

  if (!_files.length) return [];

  const contactPersonSet = new Set();
  const holdDateSet = new Set();

  for (const file of _files) {
    const { contactPerson, holdDate } = file.parsedData!;

    contactPersonSet.add(JSON.stringify(contactPerson));
    holdDateSet.add(holdDate);
  }

  if (contactPersonSet.size > 1) {
    for (const file of _files) {
      errors.get(file)!.push({ id: 'submission-form.files.errors.different-contact-person' });
    }
  }

  if (holdDateSet.size > 1) {
    for (const file of _files) {
      errors.get(file)!.push({ id: 'submission-form.files.errors.different-hold-date' });
    }
  }
}
