import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

import outdent from 'outdent';

import { AnnotationFile } from 'mssform/models/submission-file';

module('Unit | Model | annotation file', function(hooks) {
  setupTest(hooks);

  for (const newline of ['\n', '\r\n', '\r']) {
    test(`parse (newline: ${JSON.stringify(newline)})`, async function(assert) {
      assert.expect(4);

      const file = new File([outdent({newline})`
COMMON	SUBMITTER		contact	Alice Liddell
			email	alice@example.com
			institute	Wonderland Inc.
	DATE		hold_date	20200102
      `], 'foo.ann');

      const {
        contactPerson: {
          fullName,
          email,
          affiliation,
        },
        holdDate
      } = await new AnnotationFile(file).parse();

      assert.strictEqual(fullName,    'Alice Liddell');
      assert.strictEqual(email,       'alice@example.com');
      assert.strictEqual(affiliation, 'Wonderland Inc.');
      assert.strictEqual(holdDate,    '2020-01-02');
    });
  }

  test('empty' , async function(assert) {
    assert.expect(2);

    const file = new File([''], 'foo.ann');

    const {
      contactPerson,
      holdDate
    } = await new AnnotationFile(file).parse();

    assert.strictEqual(contactPerson, null);
    assert.strictEqual(holdDate,      null);
  });

  test('invalid contact person', async function(assert) {
    assert.expect(1);

    const raw = new File([outdent`
COMMON	SUBMITTER		contact	Alice Liddell
    `], 'foo.ann');

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      {id: 'annotation-file-parser.invalid-contact-person', value: undefined}
    ]);
  });

  test('invalid hold_date', async function(assert) {
    assert.expect(1);

    const raw = new File([outdent`
COMMON	DATE		hold_date	foo
    `], 'foo.ann');

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      {id: 'annotation-file-parser.invalid-hold-date', value: 'foo'}
    ]);
  });

  test('replace whitespace in filename', async function(assert) {
    assert.expect(1);

    const file      = new File([''], 'foo bar baz.ann');
    const {rawFile} = new AnnotationFile(file);

    assert.strictEqual(rawFile.name, 'foo_bar_baz.ann');
  });
});
