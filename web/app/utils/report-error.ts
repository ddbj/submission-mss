import { importSync, isTesting, macroCondition } from '@embroider/macros';

// Reports a failure that the app handled itself, so that it still reaches
// Sentry: only uncaught errors get there on their own.
export default function reportError(error: Error) {
  console.error(error);

  if (macroCondition(isTesting())) {
    // @sentry/ember is not imported in tests, see app.ts.
    return;
  }

  const Sentry = importSync('@sentry/ember') as typeof import('@sentry/ember');

  Sentry.captureException(error);
}
