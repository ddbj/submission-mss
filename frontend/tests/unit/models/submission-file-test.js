import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

import { SubmissionFile } from 'mssform/models/submission-file';

module('Unit | Model | submission file', function(hooks) {
  setupTest(hooks);

  test('invalid filename', async function(assert) {
    assert.expect(1);

    const file     = new File([''], 'こんにちは.ann');
    const {errors} = SubmissionFile.fromRawFile(file);

    assert.deepEqual(errors, [{id: 'submission-file.invalid-filename'}]);
  });

  test('unsupported filetype', async function(assert) {
    assert.expect(1);

    const file     = new File([''], 'foo.txt');
    const {errors} = SubmissionFile.fromRawFile(file);

    assert.deepEqual(errors, [{id: 'submission-file.unsupported-filetype'}]);
  });
});
