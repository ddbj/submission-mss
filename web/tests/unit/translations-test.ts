import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import translationsForEn from 'virtual:ember-intl/translations/en';
import translationsForJa from 'virtual:ember-intl/translations/ja';

import type { ExtractionError } from 'mssform/models/extraction';

type Translations = Record<string, unknown>;

function keysOf(translations: Translations, prefix = ''): string[] {
  return Object.entries(translations).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key;

    return value && typeof value === 'object' ? keysOf(value as Translations, path) : [path];
  });
}

module('Unit | translations', function (hooks) {
  setupTest(hooks);

  // There is no fallback locale, and the default is Japanese, so a key added to
  // one file alone renders as its own name to whoever reads the other.
  test('the locales say the same things', function (assert) {
    const en = keysOf(translationsForEn);
    const ja = keysOf(translationsForJa);

    assert.deepEqual(
      en.filter((key) => !ja.includes(key)),
      [],
      'English says nothing Japanese does not',
    );
    assert.deepEqual(
      ja.filter((key) => !en.includes(key)),
      [],
      'Japanese says nothing English does not',
    );
  });

  // The server sends the reason as an id and leaves the words to us. Keyed by
  // the schema's ids, so that one added there cannot go without a message.
  test('every reason an extraction is turned down for is put into words', function (assert) {
    const ids: Record<ExtractionError['id'], true> = {
      invalid_job_id: true,
      failed_to_fetch: true,
      directory_not_found: true,
      duplicate_file_name: true,
      duplicate_file_name_across_jobs: true,
      invalid_archive: true,
      broken_symlink: true,
      unreadable_file: true,
      unexpected: true,
    };

    const ja = keysOf(translationsForJa);

    assert.deepEqual(
      Object.keys(ids).filter((id) => !ja.includes(`extraction-error.${id}`)),
      [],
    );
  });
});
