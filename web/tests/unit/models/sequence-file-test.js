import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

import outdent from 'outdent';

import { SequenceFile } from 'mssform/models/submission-file';

module('Unit | Model | sequence file', function (hooks) {
  setupTest(hooks);

  for (const newline of ['\n', '\r\n', '\r']) {
    test(`parse (newline: ${JSON.stringify(newline)})`, async function (assert) {
      const raw = new File(
        [
          outdent({ newline })`
        >CLN01
        ggacaggctgccgcaggagccaggccgggagcaggaagaggcttcgggggagccggagaa
        ctgggccagatgcgcttcgtgggcgaagcctgaggaaaaagagagtgaggcaggagaatc
        gcttgaaccccggaggcggaaccgcactccagcctgggcgacagagtgagactta
        //
        >CLN02
        ctcacacagatgcgcgcacaccagtggttgtaacagaagcctgaggtgcgctcgtggtca
        gaagagggcatgcgcttcagtcgtgggcgaagcctgaggaaaaaatagtcattcatataa
        atttgaacacacctgctgtggctgtaactctgagatgtgctaaataaaccctctt
        //
      `,
        ],
        'foo.fasta',
      );

      const file = new SequenceFile(raw);
      const { entriesCount } = await file.parse();

      assert.strictEqual(entriesCount, 2);
    });
  }

  test('empty', async function (assert) {
    const raw = new File([''], 'foo.fasta');

    const file = new SequenceFile(raw);
    await file.parse();

    assert.deepEqual(file.errors, [{ id: 'sequence-file-parser.no-entries', value: undefined }]);
  });
});
