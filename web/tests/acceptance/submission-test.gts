import { module, test } from 'qunit';
import { visit, click, triggerEvent, waitUntil, fillIn } from '@ember/test-helpers';
import { setupApplicationTest } from 'mssform/tests/helpers';
import { setupAuthentication } from 'mssform/tests/helpers/setup-auth';

import { HttpResponse } from 'msw';
import { http } from '../msw/http';
import { worker } from '../msw/worker';

function clickRadio(labelText: string) {
  const labels = [...document.querySelectorAll<HTMLLabelElement>('.form-check-label')];
  const label = labels.find((el) => el.textContent?.trim().startsWith(labelText));

  if (!label) throw new Error(`Radio label not found: "${labelText}"`);

  const input = document.getElementById(label.htmlFor) as HTMLInputElement;

  if (!input) throw new Error(`Radio input not found for label: "${labelText}"`);

  return click(input);
}

module('Acceptance | submission', function (hooks) {
  setupApplicationTest(hooks);
  setupAuthentication(hooks);

  test('new submission via webui upload', async function (assert) {
    worker.use(
      http.get('/submissions', ({ response }) => {
        return response(200).json({
          submissions: [],
        });
      }),

      http.get('/submissions/last_submitted', () => {
        return new HttpResponse(null, { status: 404 });
      }),

      http.post('/submissions', ({ response }) => {
        return response(200).json({
          submission: { id: 'NSUB000001' },
        });
      }),
    );

    // --- Home page ---

    await visit('/home');
    assert.dom('h1').hasText('Home');

    await click('a[href^="/home/submissions/new"]');

    // --- Step 1: Prerequisite ---

    assert.dom('h1').hasText('New Submission');

    await clickRadio('Yes, I have determined the nucleotide sequence');
    await click('button[type="submit"]');

    // --- Step 2: Files ---

    await clickRadio('Upload the submission files through the MSS form');

    const ann = new File(
      [
        'COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n\t\t\temail\talice@example.com\n\t\t\tinstitute\tWonderland Inc.\n',
      ],
      'test.ann',
    );

    const seq = new File(['>entry1\nATCG\n'], 'test.fasta');

    await triggerEvent('input[type="file"]', 'change', { files: [ann, seq] });

    await waitUntil(() => {
      return document.querySelectorAll('.spinner-border').length === 0;
    });

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button[type="submit"]');

    // --- Step 3: Metadata ---

    await waitUntil(() => document.querySelector('#entriesCount'));

    assert.dom('#entriesCount').hasValue('1');
    assert.dom('#contactPerson\\.email').hasValue('alice@example.com');
    assert.dom('#contactPerson\\.fullName').hasValue('Alice Liddell');
    assert.dom('#contactPerson\\.affiliation').hasValue('Wonderland Inc.');

    await clickRadio('NGS');
    await fillIn('#dataType', 'wgs');
    await clickRadio('English');

    await click('button[type="submit"]');

    // --- Step 4: Confirm ---

    assert.dom('button[type="submit"]').hasText('Apply for registration');

    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => document.body.textContent?.includes('NSUB000001'));

    assert.ok(document.body.textContent?.includes('NSUB000001'), 'MASS ID is displayed');
  });

  test('new submission via DFAST job ID', async function (assert) {
    const extractionFiles = [
      {
        name: '01234567-89ab-cdef-0000-000000000001/test.ann',
        basename: 'test',
        size: 100,
        isParsing: false,
        parsedData: {
          contactPerson: { fullName: 'Alice Liddell', email: 'alice@example.com', affiliation: 'Wonderland Inc.' },
          holdDate: null,
          entriesCount: 0,
        },
        isParseSucceeded: true,
        errors: [],
        isAnnotation: true,
        isSequence: false,
        jobId: '01234567-89ab-cdef-0000-000000000001',
      },
      {
        name: '01234567-89ab-cdef-0000-000000000001/test.fasta',
        basename: 'test',
        size: 50,
        isParsing: false,
        parsedData: { entriesCount: 1 },
        isParseSucceeded: true,
        errors: [],
        isAnnotation: false,
        isSequence: true,
        jobId: '01234567-89ab-cdef-0000-000000000001',
      },
    ];

    worker.use(
      http.get('/submissions', ({ response }) => {
        return response(200).json({
          submissions: [],
        });
      }),

      http.get('/submissions/last_submitted', () => {
        return new HttpResponse(null, { status: 404 });
      }),

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
          files: extractionFiles,
        });
      }),

      http.post('/submissions', ({ response }) => {
        return response(200).json({
          submission: { id: 'NSUB000002' },
        });
      }),
    );

    // --- Home page ---

    await visit('/home');
    assert.dom('h1').hasText('Home');

    await click('a[href^="/home/submissions/new"]');

    // --- Step 1: Prerequisite ---

    assert.dom('h1').hasText('New Submission');

    await clickRadio('Yes, I have determined the nucleotide sequence');
    await click('button[type="submit"]');

    // --- Step 2: Files ---

    await clickRadio('Import the submission files from DFAST Job ID');
    await fillIn('textarea', '01234567-89ab-cdef-0000-000000000001');
    await click('.card-body button[type="submit"]');

    await waitUntil(() => {
      return document.querySelectorAll('.list-group-item').length > 0;
    });

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button.px-5[type="submit"]');

    // --- Step 3: Metadata ---

    await waitUntil(() => document.querySelector('#entriesCount'));

    assert.dom('#entriesCount').hasValue('1');
    assert.dom('#contactPerson\\.email').hasValue('alice@example.com');
    assert.dom('#contactPerson\\.fullName').hasValue('Alice Liddell');
    assert.dom('#contactPerson\\.affiliation').hasValue('Wonderland Inc.');

    await clickRadio('NGS');
    await fillIn('#dataType', 'wgs');
    await clickRadio('English');

    await click('button[type="submit"]');

    // --- Step 4: Confirm ---

    assert.dom('button[type="submit"]').hasText('Apply for registration');

    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => document.body.textContent?.includes('NSUB000002'));

    assert.ok(document.body.textContent?.includes('NSUB000002'), 'MASS ID is displayed');
  });

  test('new submission via mass directory', async function (assert) {
    const extractionFiles = [
      {
        name: 'test.ann',
        basename: 'test',
        size: 100,
        isParsing: false,
        parsedData: {
          contactPerson: { fullName: 'Alice Liddell', email: 'alice@example.com', affiliation: 'Wonderland Inc.' },
          holdDate: null,
          entriesCount: 0,
        },
        isParseSucceeded: true,
        errors: [],
        isAnnotation: true,
        isSequence: false,
      },
      {
        name: 'test.fasta',
        basename: 'test',
        size: 50,
        isParsing: false,
        parsedData: { entriesCount: 1 },
        isParseSucceeded: true,
        errors: [],
        isAnnotation: false,
        isSequence: true,
      },
    ];

    worker.use(
      http.get('/submissions', ({ response }) => {
        return response(200).json({
          submissions: [],
        });
      }),

      http.get('/submissions/last_submitted', () => {
        return new HttpResponse(null, { status: 404 });
      }),

      http.post('/mass_directory_extractions', ({ response }) => {
        return response(201).json({
          _self: '/mass_directory_extractions/1',
          id: 1,
          state: 'pending',
          error: null,
          files: [],
        });
      }),

      http.get('/mass_directory_extractions/{id}', ({ response }) => {
        return response(200).json({
          _self: '/mass_directory_extractions/1',
          id: 1,
          state: 'fulfilled',
          error: null,
          files: extractionFiles,
        });
      }),

      http.post('/submissions', ({ response }) => {
        return response(200).json({
          submission: { id: 'NSUB000003' },
        });
      }),
    );

    // --- Home page ---

    await visit('/home');
    assert.dom('h1').hasText('Home');

    await click('a[href^="/home/submissions/new"]');

    // --- Step 1: Prerequisite ---

    assert.dom('h1').hasText('New Submission');

    await clickRadio('Yes, I have determined the nucleotide sequence');
    await click('button[type="submit"]');

    // --- Step 2: Files ---

    await clickRadio('Submit all files');

    await waitUntil(() => {
      return document.querySelectorAll('.list-group-item').length > 0;
    });

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button[type="submit"]');

    // --- Step 3: Metadata ---

    await waitUntil(() => document.querySelector('#entriesCount'));

    assert.dom('#entriesCount').hasValue('1');
    assert.dom('#contactPerson\\.email').hasValue('alice@example.com');
    assert.dom('#contactPerson\\.fullName').hasValue('Alice Liddell');
    assert.dom('#contactPerson\\.affiliation').hasValue('Wonderland Inc.');

    await clickRadio('NGS');
    await fillIn('#dataType', 'wgs');
    await clickRadio('English');

    await click('button[type="submit"]');

    // --- Step 4: Confirm ---

    assert.dom('button[type="submit"]').hasText('Apply for registration');

    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => document.body.textContent?.includes('NSUB000003'));

    assert.ok(document.body.textContent?.includes('NSUB000003'), 'MASS ID is displayed');
  });
});
