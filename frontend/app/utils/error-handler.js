import { run } from '@ember/runloop';

import AdapterError from '@ember-data/adapter/error';
import Configuration from 'ember-simple-auth/configuration';
import { AppAuthError } from '@openid/appauth';

function handleError(e, status, session) {
  if (status === 400 || status === 401) {
    console.error(e);

    alert('Your session has been expired. Please re-login.');

    // To flush changes in leaving-confirmation modifier arguments.
    run(() => {
      session.leavingConfirmationDisabled = true;
    });

    if (session.isAuthenticated) {
      session.invalidate();
    } else {
      session.handleInvalidation(Configuration.rootURL);
    }

    session.leavingConfirmationDisabled = false;
  } else if (status >= 500 || status === 0) {
    console.error(e);

    alert('HTTP request failed for some reason. Please retry in a few minutes.');
  } else {
    throw e;
  }
}

export function handleFetchError(res, session) {
  if (res instanceof Response) {
    handleError(res, res.status, session);
  } else {
    throw res;
  }
}

export function handleXHRError(xhr, session) {
  if (xhr instanceof XMLHttpRequest) {
    handleError(xhr, xhr.status, session);
  } else {
    throw xhr;
  }
}

export function handleAppAuthHTTPError(e, session) {
  if (e instanceof AppAuthError && /^\d{3}$/.test(e.message)) {
    handleError(e, Number(e.message), session);
  } else {
    throw e;
  }
}

export function handleAdapterError(e, session) {
  if (e instanceof AdapterError) {
    handleError(e, Number(e.errors[0].status), session);
  } else {
    throw e;
  }
}

export function handleUploadError(e, session) {
  if (e instanceof XMLHttpRequest) {
    handleXHRError(e, session);
  } else {
    handleAppAuthHTTPError(e, session);
  }
}
