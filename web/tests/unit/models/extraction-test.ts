import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';
import { setupIntl } from 'ember-intl/test-support';
import translationsForEn from 'virtual:ember-intl/translations/en';

import Extraction from 'mssform/models/extraction';

module('Unit | Model | extraction', function (hooks) {
  setupTest(hooks);
  setupIntl(hooks, 'en', translationsForEn);

  test('a rejection is put into words from what the server sent', function (assert) {
    const extraction = new Extraction(this.owner, '/dfast_extractions/1');

    assert.strictEqual(
      extraction.describe({
        id: 'duplicate_file_name_across_jobs',
        file: 'foo.ann',
        job_id: '01234567-89ab-cdef-0000-000000000002',
        other_job_id: '01234567-89ab-cdef-0000-000000000001',
      }),
      'A file named "foo.ann" is in both of the job IDs "01234567-89ab-cdef-0000-000000000001" and "01234567-89ab-cdef-0000-000000000002". Specify only jobs whose file names do not overlap in one submission.',
    );
  });

  // Rejections stored before a field was added still have to be shown.
  test('a field the rejection does not carry is left out rather than fatal', function (assert) {
    const extraction = new Extraction(this.owner, '/dfast_extractions/1');

    assert.strictEqual(
      extraction.describe({ id: 'unreadable_file' }),
      'Could not read "". Check the permissions of the file.',
    );
  });
});
