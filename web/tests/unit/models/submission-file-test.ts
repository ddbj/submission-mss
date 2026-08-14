import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import { SubmissionFile } from 'mssform/models/submission-file';

function isAbortError(error: Error) {
  return error instanceof DOMException && error.name === 'AbortError';
}

// Hashing and parsing happen in workers, so watch the terminations at the
// source. The caller has to `restore()` whatever happens, or the counting
// subclass outlives the test.
function watchTerminatedWorkers() {
  const OriginalWorker = Worker;

  const watcher = {
    count: 0,

    restore() {
      window.Worker = OriginalWorker;
    },
  };

  window.Worker = class extends OriginalWorker {
    terminate() {
      watcher.count += 1;

      super.terminate();
    }
  };

  return watcher;
}

module('Unit | Model | submission file', function (hooks) {
  setupTest(hooks);

  test('invalid filename', function (assert) {
    const file = new File([''], 'こんにちは.ann');
    const { errors } = SubmissionFile.fromRawFile(file);

    assert.deepEqual(errors, [
      {
        severity: 'error',
        id: 'submission-file.invalid-filename',
      },
    ]);
  });

  test('unsupported filetype', function (assert) {
    const file = new File([''], 'foo.txt');
    const { errors } = SubmissionFile.fromRawFile(file);

    assert.deepEqual(errors, [
      {
        severity: 'error',
        id: 'submission-file.unsupported-filetype',
      },
    ]);
  });

  test('discarding a file stops the work still running for it', async function (assert) {
    // A half-done implementation could terminate the worker without settling
    // the promise: cap the wait rather than riding out QUnit's default timeout.
    assert.timeout(1000);

    const workers = watchTerminatedWorkers();

    try {
      const file = SubmissionFile.fromRawFile(new File(['>entry1\nATCG\n'], 'test.fasta'));

      const parsed = file.parse();
      const checksum = file.calculateDigest();

      file.dispose();

      assert.strictEqual(workers.count, 2, 'the parser and the digest worker are terminated');

      // Whoever is waiting on the file gets the same `AbortError` an abandoned
      // upload raises, rather than a promise that never settles.
      await assert.rejects(parsed, isAbortError);
      await assert.rejects(checksum, isAbortError);
    } finally {
      workers.restore();
    }
  });

  test("the digest is the file's MD5", async function (assert) {
    // The worker carries its own hashing code, so a broken bundle fails here
    // rather than in production. A worker that cannot even start reports
    // nothing at all yet, so cap the wait.
    assert.timeout(2000);

    const file = SubmissionFile.fromRawFile(new File(['>entry1\nATCG\n'], 'test.fasta'));

    assert.strictEqual(await file.calculateDigest(), 'RBpimXtNvM1ORAJCMxIaJA==');
  });

  test('a discarded file starts no further work', async function (assert) {
    // A half-done implementation could terminate the worker without settling
    // the promise: cap the wait rather than riding out QUnit's default timeout.
    assert.timeout(1000);

    const workers = watchTerminatedWorkers();

    try {
      const file = SubmissionFile.fromRawFile(new File(['>entry1\nATCG\n'], 'test.fasta'));

      file.dispose();

      await assert.rejects(file.calculateDigest(), isAbortError);

      assert.strictEqual(workers.count, 0, 'no worker is started to be terminated');
    } finally {
      workers.restore();
    }
  });
});
