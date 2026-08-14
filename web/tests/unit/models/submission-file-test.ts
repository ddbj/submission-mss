import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import { SequenceFile, SubmissionFile } from 'mssform/models/submission-file';

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

// A file whose parser script is not there to be loaded, which the worker
// reports as a bare `error` event with nothing to go by.
class MissingParserFile extends SequenceFile {
  static parser = class extends Worker {
    constructor() {
      super('/workers/no-such-worker.js');
    }
  };
}

// A file whose parser cannot even be constructed.
class UnstartableParserFile extends SequenceFile {
  static parser = class extends Worker {
    constructor() {
      // The worker has to exist before the constructor can fail, so give it a
      // script that shuts it down again.
      super('data:text/javascript,close()');

      throw new Error('the worker could not be created');
    }
  };
}

// A file whose parser starts but throws before it can answer.
class ThrowingParserFile extends SequenceFile {
  static parser = class extends Worker {
    constructor() {
      const script = URL.createObjectURL(new Blob(['throw new Error("boom")'], { type: 'text/javascript' }));

      super(script);

      URL.revokeObjectURL(script);
    }
  };
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

  test('a parser that cannot be loaded is shown on the file', async function (assert) {
    // Nothing settles the promise if the failure goes unnoticed.
    assert.timeout(2000);

    const file = new MissingParserFile(new File(['>entry1\nATCG\n'], 'test.fasta'));

    await assert.rejects(file.parse());

    assert.deepEqual(file.errors, [{ severity: 'error', id: 'submission-file.parser-failed' }]);
    assert.false(file.isParsing, 'the spinner stops');
    assert.false(file.isParseSucceeded, 'the file cannot be submitted');
  });

  test('a parser that cannot be constructed is shown on the file', async function (assert) {
    assert.timeout(2000);

    const file = new UnstartableParserFile(new File(['>entry1\nATCG\n'], 'test.fasta'));

    await assert.rejects(file.parse());

    assert.deepEqual(file.errors, [{ severity: 'error', id: 'submission-file.parser-failed' }]);
  });

  test('a parser that throws is shown on the file', async function (assert) {
    assert.timeout(2000);

    const file = new ThrowingParserFile(new File(['>entry1\nATCG\n'], 'test.fasta'));

    await assert.rejects(file.parse());

    assert.deepEqual(file.errors, [{ severity: 'error', id: 'submission-file.parser-failed' }]);
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
