import type { SubmissionError, SubmissionFileData } from 'mssform/models/submission-file';

export type CrossoverErrors = Map<SubmissionFileData, SubmissionError[]>;

export type Validation = (errors: CrossoverErrors, files: SubmissionFileData[]) => void;

// Errors a file only has in the company of the others being sent with it, as
// opposed to the ones its parser found in it on its own. Which of them apply
// is up to the form: they are not the same for a new submission and for files
// added to an existing one.
export function collectCrossoverErrors(files: SubmissionFileData[], validations: Validation[]) {
  const errors: CrossoverErrors = new Map(files.map((file) => [file, []]));

  for (const validate of validations) {
    validate(errors, files);
  }

  return errors;
}

// Whether anything stands in the way of sending these files.
export function hasBlockingErrors(files: SubmissionFileData[], crossoverErrors: CrossoverErrors) {
  for (const file of files) {
    if (file.isParsing) return true;
    if (file.errors?.some((e) => e.severity === 'error')) return true;
  }

  for (const errors of crossoverErrors.values()) {
    if (errors.some((e) => e.severity === 'error')) return true;
  }

  return false;
}

// Two files of the same kind claiming the same name, whatever the form.
export function validateDuplicates(errors: CrossoverErrors, files: SubmissionFileData[]) {
  for (const [annotations, sequences] of groupByBasename(files)) {
    if (annotations.length > 1) {
      mark(errors, annotations, 'submission-form.files.errors.duplicate-annotations');
    }

    if (sequences.length > 1) {
      mark(errors, sequences, 'submission-form.files.errors.duplicate-sequences');
    }
  }
}

// Every annotation file needs its sequence file and the other way round.
export function validatePairs(errors: CrossoverErrors, files: SubmissionFileData[]) {
  for (const [annotations, sequences] of groupByBasename(files)) {
    if (!annotations.length) {
      mark(errors, sequences, 'submission-form.files.errors.no-annotation');
    }

    if (!sequences.length) {
      mark(errors, annotations, 'submission-form.files.errors.no-sequence');
    }
  }
}

// One submission carries one contact person and one hold date, so the
// annotation files have to agree on them.
export function validateSameness(errors: CrossoverErrors, files: SubmissionFileData[]) {
  const annotations = files.filter((file) => file.fileType === 'annotation' && file.parsedData);

  if (!annotations.length) return;

  const contactPersons = new Set<string>();
  const holdDates = new Set<string>();

  for (const { parsedData } of annotations) {
    const { contactPerson, holdDate } = parsedData!;

    contactPersons.add(JSON.stringify(contactPerson));
    holdDates.add(holdDate ?? '');
  }

  if (contactPersons.size > 1) {
    mark(errors, annotations, 'submission-form.files.errors.different-contact-person');
  }

  if (holdDates.size > 1) {
    mark(errors, annotations, 'submission-form.files.errors.different-hold-date');
  }
}

// The files that share a name, split into the two halves of a pair.
function groupByBasename(files: SubmissionFileData[]) {
  const groups = new Map<string, [SubmissionFileData[], SubmissionFileData[]]>();

  for (const file of files) {
    const [annotations, sequences] = groups.get(file.basename) ?? [[], []];

    if (file.fileType === 'annotation') annotations.push(file);
    if (file.fileType === 'sequence') sequences.push(file);

    groups.set(file.basename, [annotations, sequences]);
  }

  return groups.values();
}

function mark(errors: CrossoverErrors, files: SubmissionFileData[], id: string) {
  for (const file of files) {
    errors.get(file)!.push({ severity: 'error', id });
  }
}
