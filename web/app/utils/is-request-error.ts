// Errors thrown by the RequestManager fetch chain carry `isRequestError`
// (HTTP status errors, network failures, aborts). They are already surfaced to
// the user by the error-modal handler — and server errors are captured on the
// backend — so they should not be reported to Sentry as client-side crashes.
export default function isRequestError(error: unknown): boolean {
  return typeof error === 'object' && error !== null && 'isRequestError' in error && error.isRequestError === true;
}
