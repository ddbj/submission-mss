import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

import outdent from 'outdent';

import { AnnotationFile } from 'mssform/models/submission-file';

module('Unit | Model | annotation file', function (hooks) {
  setupTest(hooks);

  for (const newline of ['\n', '\r\n', '\r']) {
    test(`parse (newline: ${JSON.stringify(newline)})`, async function (assert) {
      const file = new File(
        [
          outdent({ newline })`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\talice@example.com
\t\t\tinstitute\tWonderland Inc.
\tDATE\t\thold_date\t20200102
      `,
        ],
        'foo.ann',
      );

      const {
        contactPerson: { fullName, email, affiliation },
        holdDate,
      } = (await new AnnotationFile(file).parse()) as {
        contactPerson: { fullName: string; email: string; affiliation: string };
        holdDate: string;
      };

      assert.strictEqual(fullName, 'Alice Liddell');
      assert.strictEqual(email, 'alice@example.com');
      assert.strictEqual(affiliation, 'Wonderland Inc.');
      assert.strictEqual(holdDate, '2020-01-02');
    });
  }

  test('empty', async function (assert) {
    const raw = new File([''], 'foo.ann');

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [{ id: 'annotation-file-parser.missing-contact-person', value: undefined }]);
  });

  test('missing contact person', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tDATE\t\thold_date\t20231126
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [{ id: 'annotation-file-parser.missing-contact-person', value: undefined }]);
  });

  test('invalid contact person', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [{ id: 'annotation-file-parser.invalid-contact-person', value: undefined }]);
  });

  test('invalid email address', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\tfoo
\t\t\tinstitute\tWonderland Inc.
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [{ id: 'annotation-file-parser.invalid-email-address', value: 'foo' }]);
  });

  test('duplicate contact person information (contact)', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\tcontact\tAlice Liddell
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      { id: 'annotation-file-parser.duplicate-contact-person-information', value: undefined },
    ]);
  });

  test('duplicate contact person information (email)', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\talice@example.com
\t\t\temail\talice@example.com
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      { id: 'annotation-file-parser.duplicate-contact-person-information', value: undefined },
    ]);
  });

  test('duplicate contact person information (institute)', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\tinstitute\tWonderland Inc.
\t\t\tinstitute\tWonderland Inc.
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      { id: 'annotation-file-parser.duplicate-contact-person-information', value: undefined },
    ]);
  });

  test('invalid hold_date', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tDATE\t\thold_date\tfoo
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [{ id: 'annotation-file-parser.invalid-hold-date', value: 'foo' }]);
  });

  test('trim whitespace from contact fields', async function (assert) {
    const file = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\t Alice Liddell
\t\t\temail\t alice@example.com
\t\t\tinstitute\t Wonderland Inc.
    `,
      ],
      'foo.ann',
    );

    const {
      contactPerson: { fullName, email, affiliation },
    } = (await new AnnotationFile(file).parse()) as {
      contactPerson: { fullName: string; email: string; affiliation: string };
    };

    assert.strictEqual(fullName, 'Alice Liddell');
    assert.strictEqual(email, 'alice@example.com');
    assert.strictEqual(affiliation, 'Wonderland Inc.');
  });

  test('replace whitespace in filename', function (assert) {
    const file = new File([''], 'foo bar baz.ann');
    const { rawFile } = new AnnotationFile(file);

    assert.strictEqual(rawFile.name, 'foo_bar_baz.ann');
  });
});
