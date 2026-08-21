import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

import translationsForEn from 'virtual:ember-intl/translations/en';
import translationsForJa from 'virtual:ember-intl/translations/ja';

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
});
