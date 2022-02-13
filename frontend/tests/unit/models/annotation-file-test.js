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

    const file = new File([outdent`
    `], 'foo.ann');

    const {
      contactPerson,
      holdDate
    } = await new AnnotationFile(file).parse();

    assert.strictEqual(contactPerson, null);
    assert.strictEqual(holdDate,      null);
  });

  test('invalid contact person', async function(assert) {
    assert.expect(1);

    const file = new File([outdent`
COMMON	SUBMITTER		contact	Alice Liddell
    `], 'foo.ann');

    assert.rejects(
      new AnnotationFile(file).parse(),
      /^Contact person information \(contact, email, institute\) must be included or not included at all\./
    );
  });

  test('invalid hold_date', async function(assert) {
    assert.expect(1);

    const file = new File([outdent`
COMMON	DATE		hold_date	foo
    `], 'foo.ann');

    assert.rejects(
      new AnnotationFile(file).parse(),
      /hold_date must be an 8-digit number \(YYYYMMDD\), but: foo/
    );
  });
});
