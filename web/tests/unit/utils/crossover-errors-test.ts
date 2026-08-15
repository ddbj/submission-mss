import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import {
  collectCrossoverErrors,
  hasBlockingErrors,
  validateDuplicates,
  validatePairs,
  validateSameness,
} from 'mssform/utils/crossover-errors';

import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

interface FileOptions {
  parsedData?: SubmissionFileData['parsedData'];
  errors?: SubmissionError[];
  isParsing?: boolean;
}

function file(name: string, fileType: 'annotation' | 'sequence', options: FileOptions = {}): SubmissionFileData {
  const { parsedData, errors = [], isParsing = false } = options;

  return {
    name,
    basename: name,
    size: 1,
    fileType,
    isParsing,
    parsedData,
    isParseSucceeded: Boolean(parsedData),
    errors,
  };
}

function contactPerson(email: string) {
  return { email, fullName: 'Alice Liddell', affiliation: 'Wonderland Inc.' };
}

function idsFor(errors: Map<SubmissionFileData, SubmissionError[]>, target: SubmissionFileData) {
  return errors.get(target)!.map((error) => error.id);
}

module('Unit | Utility | crossover errors', function (hooks) {
  setupTest(hooks);

  test('a pair is complete', function (assert) {
    const annotation = file('foo', 'annotation');
    const sequence = file('foo', 'sequence');
    const files = [annotation, sequence];

    const errors = collectCrossoverErrors(files, [validateDuplicates, validatePairs]);

    assert.deepEqual(idsFor(errors, annotation), []);
    assert.deepEqual(idsFor(errors, sequence), []);
  });

  test('a half of a pair is missing', function (assert) {
    const annotation = file('foo', 'annotation');
    const orphan = file('bar', 'sequence');
    const files = [annotation, file('foo', 'sequence'), orphan];

    const errors = collectCrossoverErrors(files, [validatePairs]);

    assert.deepEqual(idsFor(errors, orphan), ['submission-form.files.errors.no-annotation']);
    assert.deepEqual(idsFor(errors, annotation), [], 'the complete pair is left alone');
  });

  test('a half of a pair is missing, where that is allowed', function (assert) {
    const orphan = file('bar', 'sequence');

    // What a re-upload replacing one half of a pair looks like.
    const errors = collectCrossoverErrors([orphan], [validateDuplicates]);

    assert.deepEqual(idsFor(errors, orphan), []);
  });

  test('the same file twice', function (assert) {
    const first = file('foo', 'annotation');
    const second = file('foo', 'annotation');

    const errors = collectCrossoverErrors([first, second], [validateDuplicates]);

    assert.deepEqual(idsFor(errors, first), ['submission-form.files.errors.duplicate-annotations']);
    assert.deepEqual(idsFor(errors, second), ['submission-form.files.errors.duplicate-annotations']);
  });

  test('the annotation files disagree', function (assert) {
    const alice = file('foo', 'annotation', {
      parsedData: { contactPerson: contactPerson('alice@example.com'), holdDate: '2020-01-02' },
    });

    const bob = file('bar', 'annotation', {
      parsedData: { contactPerson: contactPerson('bob@example.com'), holdDate: '2030-04-05' },
    });

    const errors = collectCrossoverErrors([alice, bob], [validateSameness]);

    assert.deepEqual(idsFor(errors, alice), [
      'submission-form.files.errors.different-contact-person',
      'submission-form.files.errors.different-hold-date',
    ]);
  });

  test('files that are still being read block', function (assert) {
    const files = [file('foo', 'annotation', { isParsing: true })];

    assert.true(hasBlockingErrors(files, collectCrossoverErrors(files, [])));
  });

  test('a warning does not block', function (assert) {
    const files = [file('foo', 'annotation', { errors: [{ severity: 'warning', id: 'whatever' }] })];

    assert.false(hasBlockingErrors(files, collectCrossoverErrors(files, [])));
  });

  test('an error blocks, wherever it comes from', function (assert) {
    const withOwnError = [file('foo', 'annotation', { errors: [{ severity: 'error', id: 'whatever' }] })];

    assert.true(hasBlockingErrors(withOwnError, collectCrossoverErrors(withOwnError, [])));

    const duplicated = [file('foo', 'annotation'), file('foo', 'annotation')];

    assert.true(hasBlockingErrors(duplicated, collectCrossoverErrors(duplicated, [validateDuplicates])));
  });
});
