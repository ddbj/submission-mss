import { module, test } from 'qunit';

import isRequestError from 'mssform/utils/is-request-error';

module('Unit | Utility | is-request-error', function () {
  test('true for errors thrown by the request chain', function (assert) {
    const forbidden = Object.assign(new Error('[403 Forbidden] POST - /uploads'), {
      isRequestError: true,
      status: 403,
    });

    assert.true(isRequestError(forbidden));
  });

  test('false for unexpected client-side errors', function (assert) {
    // e.g. MSSFORM-60: these must still reach Sentry.
    assert.false(isRequestError(new TypeError("Cannot read properties of undefined (reading 'id')")));
    assert.false(isRequestError(new Error('boom')));
  });

  test('false for non-errors and non-request flags', function (assert) {
    assert.false(isRequestError(undefined));
    assert.false(isRequestError(null));
    assert.false(isRequestError('directory_not_found'));
    assert.false(isRequestError({ isRequestError: false }));
  });
});
