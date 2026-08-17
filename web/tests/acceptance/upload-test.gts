import { module, test } from 'qunit';
import {
  visit,
  click,
  currentURL,
  fillIn,
  findAll,
  settled,
  triggerEvent,
  waitFor,
  waitUntil,
} from '@ember/test-helpers';
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

  // The files of an upload are copied by a background job, so a fresh one is
  // listed with none of them yet.
  let uploads: { id: number; created_at: string; files: string[]; job_ids: string[] }[];

  hooks.beforeEach(function () {
    uploads = [];

    worker.use(
      http.get('/submissions/{mass_id}', ({ response }) => {
        return response(200).json({
          submission: {
            id: 'NSUB000001',
            created_at: '2026-08-14T00:00:00Z',
            status: null,
            accessions: [],
            uploads,
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
        uploads = [{ id: 1, created_at: '2026-08-16T00:00:00Z', files: [], job_ids: [] }];

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

    // Sending is not tracked by `settled`, so wait for where it ends up. The
    // query string carries the locale, and this page's own URL starts with the
    // one it leaves for.
    await waitUntil(() => currentURL()?.split('?')[0] === '/home/submission/NSUB000001');
    await settled();

    assert.deepEqual(uploaded, { upload: { via: 'webui', files: ['test-signed-id'] } });

    // The submission lists what was just added to it, which is the answer the
    // submitter is after.
    assert.dom('.card').exists({ count: 1 }, 'the upload is listed');
  });

  test('adding files imported from a job', async function (assert) {
    let uploaded: unknown;

    worker.use(
      http.post('/dfast_extractions', ({ response }) => {
        return response(201).json({
          _self: '/dfast_extractions/1',
          id: 1,
          state: 'pending',
          error: null,
          files: [],
        });
      }),

      http.get('/dfast_extractions/{id}', ({ response }) => {
        return response(200).json({
          _self: '/dfast_extractions/1',
          id: 1,
          state: 'fulfilled',
          error: null,

          files: [
            {
              name: '01234567-89ab-cdef-0000-000000000001/test.fasta',
              basename: 'test',
              size: 50,
              isParsing: false,
              parsedData: { entriesCount: 1 },
              isParseSucceeded: true,
              errors: [],
              fileType: 'sequence' as const,
              jobId: '01234567-89ab-cdef-0000-000000000001',
            },
          ],
        });
      }),

      http.post('/submissions/{mass_id}/uploads', async ({ request }) => {
        uploaded = await request.json();
        uploads = [{ id: 1, created_at: '2026-08-16T00:00:00Z', files: [], job_ids: [] }];

        return new HttpResponse(null, { status: 204 });
      }),
    );

    await visit('/home/submission/NSUB000001/upload');

    await clickRadio('Import the submission files from DFAST Job ID');
    await fillIn('textarea', '01234567-89ab-cdef-0000-000000000001');
    await click('.card-body button[type="submit"]');

    await waitFor('.list-group-item');

    await click('button.px-5[type="submit"]');

    await waitUntil(() => currentURL()?.split('?')[0] === '/home/submission/NSUB000001');

    // An import sends what to copy, not the files themselves.
    assert.deepEqual(uploaded, { upload: { via: 'dfast', extraction_id: 1 } });
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
