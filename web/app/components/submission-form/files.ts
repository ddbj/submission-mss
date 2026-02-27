import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { task } from 'ember-concurrency';

import OtherPerson from 'mssform/models/other-person';

import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';
import type RequestService from 'mssform/services/request';
import type { SubmissionFile } from 'mssform/models/submission-file';

interface CrossoverError {
  id: string;
}

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormFilesComponent extends Component<Signature> {
  @service declare request: RequestService;

  get crossoverErrors() {
    const { files } = this.args.state;
    const errors = new Map<SubmissionFile, CrossoverError[]>();

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

  @action setUploadVia(val: string) {
    this.args.model.uploadVia = val;
    this.args.model.extractionId = undefined;
    this.args.state.files = [];
  }

  @action onExtractProgress({ id, files }: { id: string; files: SubmissionFile[] }) {
    this.args.model.extractionId = id;
    this.args.state.files = files;
  }

  @action addFile(file: SubmissionFile) {
    this.args.state.files = [...this.args.state.files, file];
  }

  @action removeFile(file: SubmissionFile) {
    this.args.state.files = this.args.state.files.filter((f) => f !== file);
  }

  goNext = task({ drop: true }, async () => {
    await this.fillDataFromLastSubmission();
    this.fillDataFromSubmissionFiles();

    this.args.nav.goNext();
  });

  async fillDataFromLastSubmission() {
    let last:
      | {
          contact_person: { email: string; fullName: string; affiliation: string };
          other_people: { email: string; full_name: string }[];
          sequencer: string;
          email_language: string;
        }
      | undefined;

    try {
      const res = await this.request.fetch('/submissions/last_submitted');

      last = ((await res.json()) as { submission: typeof last }).submission;
    } catch {
      // do nothing
    }

    if (!last) return;

    const { model } = this.args;

    model.contactPerson.email = last.contact_person.email;
    model.contactPerson.fullName = last.contact_person.fullName;
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

    const annotationFile = files.find((file) => 'isAnnotation' in file && file.isAnnotation);

    const { contactPerson, holdDate } = (annotationFile?.parsedData ?? {}) as {
      contactPerson?: Record<string, string>;
      holdDate?: string;
    };

    Object.assign(model.contactPerson, contactPerson ?? {});

    model.holdDate = holdDate;

    model.entriesCount = files
      .filter((file) => 'isSequence' in file && file.isSequence)
      .reduce((acc, file) => {
        return acc + ((file.parsedData as { entriesCount: number } | undefined)?.entriesCount ?? 0);
      }, 0);
  }
}

function validatePair(errors: Map<SubmissionFile, CrossoverError[]>, files: SubmissionFile[]) {
  const grouped = files.reduce((map, file) => {
    const val = map.has(file.basename) ? [...map.get(file.basename)!, file] : [file];

    return map.set(file.basename, val);
  }, new Map<string, SubmissionFile[]>());

  for (const files of grouped.values()) {
    const [annotations, sequences] = files.reduce(
      ([ann, seq], file) => {
        const isAnnotation = 'isAnnotation' in file && file.isAnnotation;
        const isSequence = 'isSequence' in file && file.isSequence;

        return [isAnnotation ? [...ann, file] : ann, isSequence ? [...seq, file] : seq];
      },
      [[], []] as [SubmissionFile[], SubmissionFile[]],
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

function validateSameness(errors: Map<SubmissionFile, CrossoverError[]>, files: SubmissionFile[]) {
  const filtered = files.filter((file) => 'isAnnotation' in file && file.isAnnotation && file.isParseSucceeded);

  if (!filtered.length) return;

  const contactPersonSet = new Set<string>();
  const holdDateSet = new Set<string>();

  for (const file of filtered) {
    const { contactPerson, holdDate } = file.parsedData as { contactPerson: unknown; holdDate: string };

    contactPersonSet.add(JSON.stringify(contactPerson));
    holdDateSet.add(holdDate);
  }

  if (contactPersonSet.size > 1) {
    for (const file of filtered) {
      errors.get(file)!.push({ id: 'submission-form.files.errors.different-contact-person' });
    }
  }

  if (holdDateSet.size > 1) {
    for (const file of filtered) {
      errors.get(file)!.push({ id: 'submission-form.files.errors.different-hold-date' });
    }
  }
}
