import type { SubmissionFile, SubmissionError } from 'mssform/models/submission-file';

export default function errorsFor(
  file: SubmissionFile,
  crossoverErrors: Map<SubmissionFile, SubmissionError[]>,
): SubmissionError[] {
  return [...file.errors, ...(crossoverErrors.get(file) ?? [])];
}
