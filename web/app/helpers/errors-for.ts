import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

export default function errorsFor(
  file: SubmissionFileData,
  crossoverErrors: Map<SubmissionFileData, SubmissionError[]>,
): SubmissionError[] {
  return [...(file.errors ?? []), ...(crossoverErrors.get(file) ?? [])];
}
