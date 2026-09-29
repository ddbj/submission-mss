import { module, test } from 'qunit';
import { setupTest } from 'mssform/tests/helpers';

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

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.missing-contact-person',
        value: undefined,
      },
    ]);
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

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.missing-contact-person',
        value: undefined,
      },
    ]);
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

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.invalid-contact-person',
        value: undefined,
      },
    ]);
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

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.invalid-email-address',
        value: 'foo',
      },
    ]);
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
      {
        severity: 'error',
        id: 'annotation-file-parser.duplicate-contact-person-information',
        value: undefined,
      },
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
      {
        severity: 'error',
        id: 'annotation-file-parser.duplicate-contact-person-information',
        value: undefined,
      },
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
      {
        severity: 'error',
        id: 'annotation-file-parser.duplicate-contact-person-information',
        value: undefined,
      },
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

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.invalid-hold-date',
        value: 'foo',
      },
    ]);
  });

  // What DFAST leaves in the file when it is run without its metadata: the
  // qualifiers are there, their values are not.
  test('blank contact person', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\t
\t\t\temail\t
\t\t\tinstitute
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.missing-contact-person',
        value: undefined,
      },
    ]);
  });

  test('blank contact name', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\t\u3000
\t\t\temail\talice@example.com
\t\t\tinstitute\tWonderland Inc.
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.invalid-contact-person',
        value: undefined,
      },
    ]);
  });

  test('blank email address', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\t${' '}
\t\t\tinstitute\tWonderland Inc.
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [
      {
        severity: 'error',
        id: 'annotation-file-parser.invalid-contact-person',
        value: undefined,
      },
    ]);
  });

  test('a blank line is not a second contact person', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\tcontact\t
\t\t\temail\talice@example.com
\t\t\tinstitute\tWonderland Inc.
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, []);
    assert.strictEqual(file.parsedData?.contactPerson?.fullName, 'Alice Liddell');
  });

  for (const line of [
    'hold_date\t',
    'hold_date',
    'hold_date\t  ',
    'hold_date\t20250229',
    'hold_date\t20251301',
    'hold_date\t15000229',
  ]) {
    test(`blank or impossible hold_date (${JSON.stringify(line)})`, async function (assert) {
      const raw = new File([`COMMON\tDATE\t\t${line}\n`], 'foo.ann');

      const file = new AnnotationFile(raw);
      await file.parse();

      assert.deepEqual(file.errors, [
        {
          severity: 'error',
          id: 'annotation-file-parser.invalid-hold-date',
          value: line.split('\t')[1]?.trim() || undefined,
        },
      ]);
    });
  }

  // The day before the Gregorian reform, which only a Julian calendar skips.
  test('a hold date counted in the Gregorian calendar', async function (assert) {
    const file = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\talice@example.com
\t\t\tinstitute\tWonderland Inc.
\tDATE\t\thold_date\t15821010
      `,
      ],
      'foo.ann',
    );

    const parsedData = await new AnnotationFile(file).parse();

    assert.strictEqual(parsedData?.holdDate, '1582-10-10');
  });

  test('byte order mark', async function (assert) {
    const file = new File(
      [
        '\uFEFF',
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\talice@example.com
\t\t\tinstitute\tWonderland Inc.
      `,
      ],
      'foo.ann',
    );

    const parsedData = await new AnnotationFile(file).parse();

    assert.strictEqual(parsedData?.contactPerson?.fullName, 'Alice Liddell');
  });

  test('temporary locus_tag', async function (assert) {
    const raw = new File(
      [
        outdent`
COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
\t\t\temail\talice@example.com
\t\t\tinstitute\tWonderland Inc.
CLN01\tgene\t1..100\tlocus_tag\tlocus_0001
\tgene\t101..200\tlocus_tag\tLOCUS_0002
\tgene\t201..300\tlocus_tag\tLocus_0003
    `,
      ],
      'foo.ann',
    );

    const file = new AnnotationFile(raw);
    const parsedData = await file.parse();

    assert.deepEqual(file.errors, [
      {
        severity: 'warning',
        id: 'annotation-file-parser.temporary-locus-tag',
        value: 'locus_0001',
      },
      {
        severity: 'warning',
        id: 'annotation-file-parser.temporary-locus-tag',
        value: 'LOCUS_0002',
      },
      {
        severity: 'warning',
        id: 'annotation-file-parser.temporary-locus-tag',
        value: 'Locus_0003',
      },
    ]);

    assert.ok(parsedData, 'parsedData should still be set');
    assert.strictEqual(file.parsedData?.contactPerson?.fullName, 'Alice Liddell');
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
