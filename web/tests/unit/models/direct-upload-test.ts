import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import { http as mswHttp } from 'msw';
import ENV from 'mssform/config/environment';

import { DirectUpload } from 'mssform/models/direct-upload';
import { worker } from '../../msw/worker';

function buildUpload(signal: AbortSignal, willStoreFile: () => void = () => {}) {
  return new DirectUpload(
    new File(['>entry1\nATCG\n'], 'test.fasta'),
    ENV.directUploadURL,
    {
      directUploadWillCreateBlobWithXHR: () => {},
      directUploadWillStoreFileWithXHR: willStoreFile,
    },
    Promise.resolve('checksum'),
    signal,
  );
}

function isAbortError(error: Error) {
  return error instanceof DOMException && error.name === 'AbortError';
}

module('Unit | Model | direct upload', function (hooks) {
  setupTest(hooks);

  test('abort before the request is sent', async function (assert) {
    const abort = new AbortController();
    const created = buildUpload(abort.signal).create();

    abort.abort();

    await assert.rejects(created, isAbortError);
  });

  test('abort while the file is being stored', async function (assert) {
    // Without the fix, `create` never settles: fail fast instead of waiting out
    // QUnit's default timeout.
    assert.timeout(1000);

    // The storage request never answers, so the upload is still running when
    // it is aborted.
    worker.use(mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => new Promise<Response>(() => {})));

    const abort = new AbortController();

    let storing!: () => void;

    const stored = new Promise<void>((resolve) => {
      storing = resolve;
    });

    const created = buildUpload(abort.signal, storing).create();

    await stored;

    abort.abort();

    // Active Storage listens for `load` and `error` only, so an aborted
    // request would leave `create` pending forever.
    await assert.rejects(created, isAbortError);
  });
});
