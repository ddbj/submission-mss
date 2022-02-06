import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

import outdent from 'outdent';

import { AnnotationFile } from 'mssform/models/submission-file';

module('Unit | Model | annotation file', function(hooks) {
  setupTest(hooks);

  for (const newline of ['\n', '\r\n', '\r']) {
    test(`annotation file (newline: ${JSON.stringify(newline)})`, async function(assert) {
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
      } = await new AnnotationFile(file).parse();

      assert.strictEqual(fullName,    'Alice Liddell');
      assert.strictEqual(email,       'alice@example.com');
      assert.strictEqual(affiliation, 'Wonderland Inc.');
      assert.strictEqual(holdDate,    '2020-01-02');
    });
  }
});
