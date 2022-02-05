import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

import outdent from 'outdent';

module('Unit | Service | file-parser', function(hooks) {
  setupTest(hooks);

  for (const newline of ['\n', '\r\n', '\r']) {
    test(`annotation file (newline: ${JSON.stringify(newline)})`, async function(assert) {
      const service = this.owner.lookup('service:file-parser');

      const file = new File([outdent({newline})`
COMMON	SUBMITTER		contact	Alice Liddell
			email	alice@example.com
			institute	Wonderland Inc.
	DATE		hold_date	20200102
      `], 'foo.ann');

      const {
        fullName,
        email,
        affiliation,
        holdDate
      } = await service.parse('annotation', file);

      assert.strictEqual(fullName,    'Alice Liddell');
      assert.strictEqual(email,       'alice@example.com');
      assert.strictEqual(affiliation, 'Wonderland Inc.');
      assert.strictEqual(holdDate,    '2020-01-02');
    });
  }

  for (const newline of ['\n', '\r\n', '\r']) {
    test(`sequence file (newline: ${JSON.stringify(newline)})`, async function(assert) {
      const service = this.owner.lookup('service:file-parser');

      const file = new File([outdent({newline})`
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
      `], 'foo.ann');

      const {entriesCount} = await service.parse('sequence', file);

      assert.strictEqual(entriesCount, 2);
    });
  }
});
