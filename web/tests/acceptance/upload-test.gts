import { module, test } from 'qunit';
import { visit, click, findAll, getRootElement, triggerEvent, waitUntil } from '@ember/test-helpers';
import { setupApplicationTest } from 'mssform/tests/helpers';
import { setupAuthentication } from 'mssform/tests/helpers/setup-auth';
import clickRadio from 'mssform/tests/helpers/click-radio';

import { HttpResponse } from 'msw';
import { http } from '../msw/http';
import { worker } from '../msw/worker';

function annotationFile(name = 'test.ann', contact = 'Alice Liddell') {
  const lines = [
    `COMMON\tSUBMITTER\t\tcontact\t${contact}\n`,
    '\t\t\temail\talice@example.com\n',
    '\t\t\tinstitute\tWonderland Inc.\n',
    'CLN01\tgene\t1..100\tlocus_tag\tLOCUS_0001\n',
  ];

  return new File([lines.join('')], name);
}

function sequenceFile(name = 'test.fasta') {
  return new File(['>entry1\nATCG\n'], name);
}

// Files land on the form parsed and hashed; nothing is submitted until they are.
async function addFiles(files: File[]) {
  await triggerEvent('input[type="file"]', 'change', { files });

  await waitUntil(() => findAll('.spinner-border').length === 0);
}

module('Acceptance | upload', function (hooks) {
  setupApplicationTest(hooks);
  setupAuthentication(hooks);

  hooks.beforeEach(function () {
    worker.use(
      http.get('/submissions/{mass_id}', ({ response }) => {
        return response(200).json({
          submission: {
            id: 'NSUB000001',
            created_at: '2026-08-14T00:00:00Z',
            status: null,
            accessions: [],
            uploads: [],
          },
        });
      }),
    );
  });

  test('adding the half of a pair that changed', async function (assert) {
    let uploaded: unknown;

    worker.use(
      http.post('/submissions/{mass_id}/uploads', async ({ request }) => {
        uploaded = await request.json();

        return new HttpResponse(null, { status: 204 });
      }),
    );

    await visit('/home/submission/NSUB000001/upload');

    await clickRadio('Upload the submission files through the MSS form');

    // Re-uploading a sequence file on its own is the point of this form: the
    // annotation file it belongs to was submitted before.
    await addFiles([sequenceFile()]);

    assert.dom('button.px-5[type="submit"]').isNotDisabled('a file without its pair can be sent');

    await click('button.px-5[type="submit"]');

    await waitUntil(() => getRootElement().textContent?.includes('Go to home'));

    assert.deepEqual(uploaded, { upload: { via: 'webui', files: ['test-signed-id'] } });
  });

  test('a warning does not stand in the way', async function (assert) {
    await visit('/home/submission/NSUB000001/upload');

    await clickRadio('Upload the submission files through the MSS form');

    // The annotation file carries a temporary locus_tag, which is reported as
    // a warning and cannot be acted on: it must not block the upload.
    await addFiles([annotationFile(), sequenceFile()]);

    assert.dom('.list-group-item').exists({ count: 2 });
    assert.dom('.list-group-item').containsText('LOCUS_0001', 'the warning is shown');
    assert.dom('button.px-5[type="submit"]').isNotDisabled();
  });

  test('the annotation files disagree with each other', async function (assert) {
    await visit('/home/submission/NSUB000001/upload');

    await clickRadio('Upload the submission files through the MSS form');

    // The submission has one contact person, so annotation files sent together
    // cannot name two -- there is nowhere else this would be caught.
    await addFiles([annotationFile('foo.ann'), annotationFile('bar.ann', 'Bob Carroll')]);

    assert.dom('.list-group-item').containsText('are not the same');
    assert.dom('button.px-5[type="submit"]').isDisabled();
  });

  test('the same file twice', async function (assert) {
    await visit('/home/submission/NSUB000001/upload');

    await clickRadio('Upload the submission files through the MSS form');

    await addFiles([sequenceFile(), sequenceFile()]);

    for (const item of findAll('.list-group-item')) {
      assert.dom(item).containsText('Duplicate sequence files with the same name exist.');
    }

    assert.dom('.list-group-item').exists({ count: 2 }, 'both files are flagged');
    assert.dom('button.px-5[type="submit"]').isDisabled();
  });
});
