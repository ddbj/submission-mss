import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import FileSelection from 'mssform/models/file-selection';
import { validatePairs } from 'mssform/utils/crossover-errors';

import type { SubmissionFileData } from 'mssform/models/submission-file';

function file(name: string, fileType: 'annotation' | 'sequence', isParsing = false): SubmissionFileData {
  return {
    name,
    basename: name,
    size: 1,
    fileType,
    isParsing,
    parsedData: null,
    isParseSucceeded: !isParsing,
    errors: [],
  };
}

module('Unit | Model | file selection', function (hooks) {
  setupTest(hooks);

  // Said beside the button in this order: each is what to see to first.
  test('why the files cannot be sent yet', function (assert) {
    const selection = new FileSelection([validatePairs]);

    assert.strictEqual(selection.whyNotSubmittable, 'no-via');

    selection.setVia('mass_directory');

    assert.strictEqual(selection.whyNotSubmittable, 'no-files');

    selection.onExtractStart();
    selection.onExtractProgress({ id: 1, state: 'pending', files: [] });

    assert.strictEqual(selection.whyNotSubmittable, 'extracting', 'not "no files": they are on their way');

    selection.onExtractProgress({ id: 1, state: 'fulfilled', files: [file('foo', 'annotation')] });
    selection.onExtractEnd();

    assert.strictEqual(selection.whyNotSubmittable, 'errors', 'the annotation file has no sequence file');
    assert.false(selection.isSubmittable);

    selection.onExtractStart();
    selection.onExtractProgress({
      id: 2,
      state: 'fulfilled',
      files: [file('foo', 'annotation'), file('foo', 'sequence')],
    });
    selection.onExtractEnd();

    assert.strictEqual(selection.whyNotSubmittable, undefined);
    assert.true(selection.isSubmittable);
  });

  test('an extraction turned down', function (assert) {
    const selection = new FileSelection([]);

    selection.setVia('dfast');
    selection.onExtractStart();
    selection.onExtractProgress({ id: 1, state: 'rejected', files: [] });
    selection.onExtractEnd();

    assert.strictEqual(selection.whyNotSubmittable, 'rejected', 'not "no files": none are coming');

    selection.onExtractStart();

    assert.strictEqual(selection.whyNotSubmittable, 'extracting', 'forgotten with the next attempt');
  });

  // The request failed, and the error modal said so: nothing is on its way.
  test('an extraction that ends without a word', function (assert) {
    const selection = new FileSelection([]);

    selection.setVia('dfast');
    selection.onExtractStart();
    selection.onExtractEnd();

    assert.strictEqual(selection.whyNotSubmittable, 'no-files');
  });

  test('an error already found goes before files still being read', function (assert) {
    const selection = new FileSelection([]);

    selection.setVia('webui');
    selection.addFile({ ...file('foo', 'annotation'), errors: [{ severity: 'error', id: 'whatever' }] });
    selection.addFile(file('bar', 'sequence', true));

    assert.strictEqual(selection.whyNotSubmittable, 'errors');
  });
});
