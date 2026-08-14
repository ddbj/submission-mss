import { module, test } from 'qunit';
import {
  visit,
  click,
  findAll,
  getRootElement,
  settled,
  triggerEvent,
  waitFor,
  waitUntil,
  fillIn,
} from '@ember/test-helpers';
import { setupApplicationTest } from 'mssform/tests/helpers';
import { setupAuthentication } from 'mssform/tests/helpers/setup-auth';
import clickRadio from 'mssform/tests/helpers/click-radio';

import { HttpResponse, http as mswHttp } from 'msw';
import ENV from 'mssform/config/environment';
import { SubmissionFile } from 'mssform/models/submission-file';
import { http } from '../msw/http';
import { worker } from '../msw/worker';

// Every DOM lookup below goes through the test helpers, which are scoped to the
// application's root element. Querying `document` instead would also match the
// Bootstrap modals that a previous test leaked into `<body>`: Bootstrap
// re-appends a modal there if its show transition is still pending when the
// application is torn down.

// Walks a webui upload from the home page to the confirm step, with the terms
// agreed to, leaving the caller to submit the application.
async function fillInWebuiSubmission() {
  await visit('/home');

  await click('a[href^="/home/submissions/new"]');

  // --- Step 1: Prerequisite ---

  await clickRadio('Yes, I have determined the nucleotide sequence');
  await click('button[type="submit"]');

  // --- Step 2: Files ---

  await clickRadio('Upload the submission files through the MSS form');

  const ann = new File(
    ['COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n\t\t\temail\talice@example.com\n\t\t\tinstitute\tWonderland Inc.\n'],
    'test.ann',
  );

  const seq = new File(['>entry1\nATCG\n'], 'test.fasta');

  await triggerEvent('input[type="file"]', 'change', { files: [ann, seq] });

  await waitUntil(() => findAll('.spinner-border').length === 0);

  await click('button[type="submit"]');

  // --- Step 3: Metadata ---

  await waitFor('#entriesCount');

  await clickRadio('NGS');
  await fillIn('#dataType', 'wgs');
  await clickRadio('English');

  await click('button[type="submit"]');

  // --- Step 4: Confirm ---

  await click('#agree-terms');
}

// Active Storage uploads over XHR, and msw does not tell its handlers when a
// client hangs up on one, so count the aborts at the source. The caller has to
// `restore()` whatever happens, or the counting subclass outlives the test.
function watchAbortedRequests() {
  const OriginalXHR = XMLHttpRequest;

  const watcher = {
    count: 0,

    restore() {
      window.XMLHttpRequest = OriginalXHR;
    },
  };

  window.XMLHttpRequest = class extends OriginalXHR {
    abort() {
      watcher.count += 1;

      super.abort();
    }
  };

  return watcher;
}

// Holds the digest back, so an upload can be cancelled while its checksum is
// still being calculated. The caller has to `restore()` whatever happens.
function stallDigest() {
  const original = Object.getOwnPropertyDescriptor(SubmissionFile.prototype, 'calculateDigest')!;

  const digest = {
    finish: undefined as ((checksum: string) => void) | undefined,

    restore() {
      Object.defineProperty(SubmissionFile.prototype, 'calculateDigest', original);
    },
  };

  SubmissionFile.prototype.calculateDigest = function (this: SubmissionFile) {
    this.checksum = new Promise<string>((resolve) => {
      digest.finish = resolve;
    });

    return this.checksum;
  };

  return digest;
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

    await waitUntil(() => findAll('.spinner-border').length === 0);

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button[type="submit"]');

    // --- Step 3: Metadata ---

    await waitFor('#entriesCount');

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

    assert.dom('button.px-5[type="submit"]').isDisabled('Submit is disabled until the terms are agreed to');

    await click('#agree-terms');

    assert.dom('button.px-5[type="submit"]').isNotDisabled('Submit is enabled once the terms are agreed to');

    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => getRootElement().textContent?.includes('NSUB000001'));

    assert.dom().containsText('NSUB000001', 'MASS ID is displayed');
  });

  test('the unacceptable TPA answer cannot proceed past the prerequisite step', async function (assert) {
    worker.use(
      http.get('/submissions', ({ response }) => {
        return response(200).json({
          submissions: [],
        });
      }),

      http.get('/submissions/last_submitted', () => {
        return new HttpResponse(null, { status: 404 });
      }),
    );

    await visit('/home');
    await click('a[href^="/home/submissions/new"]');

    // --- Step 1: Prerequisite ---

    await clickRadio('No, I have created the nucleotide sequences by assembling from the publicly available data.');
    await clickRadio('No, I have no plan to submit a paper.');

    assert.dom('form').containsText('you cannot apply to MSS unless you will prepare a paper');
    assert.dom('button.px-5[type="submit"]').isDisabled('Next stays disabled for the unacceptable TPA answer');
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
        fileType: 'annotation' as const,
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
        fileType: 'sequence' as const,
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

    await waitFor('.list-group-item');

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button.px-5[type="submit"]');

    // --- Step 3: Metadata ---

    await waitFor('#entriesCount');

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

    await click('#agree-terms');
    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => getRootElement().textContent?.includes('NSUB000002'));

    assert.dom().containsText('NSUB000002', 'MASS ID is displayed');
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
        fileType: 'annotation' as const,
      },
      {
        name: 'test.fasta',
        basename: 'test',
        size: 50,
        isParsing: false,
        parsedData: { entriesCount: 1 },
        isParseSucceeded: true,
        errors: [],
        fileType: 'sequence' as const,
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

    await waitFor('.list-group-item');

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button[type="submit"]');

    // --- Step 3: Metadata ---

    await waitFor('#entriesCount');

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

    await click('#agree-terms');
    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => getRootElement().textContent?.includes('NSUB000003'));

    assert.dom().containsText('NSUB000003', 'MASS ID is displayed');
  });

  test('new submission via GGS job ID', async function (assert) {
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
        fileType: 'annotation' as const,
        jobId: '01234567-89ab-cdef-0000-000000000001',
      },
      {
        name: 'test.fa',
        basename: 'test',
        size: 50,
        isParsing: false,
        parsedData: { entriesCount: 1 },
        isParseSucceeded: true,
        errors: [],
        fileType: 'sequence' as const,
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

      http.post('/ggs_extractions', ({ response }) => {
        return response(201).json({
          _self: '/ggs_extractions/1',
          id: 1,
          state: 'pending',
          error: null,
          files: [],
        });
      }),

      http.get('/ggs_extractions/{id}', ({ response }) => {
        return response(200).json({
          _self: '/ggs_extractions/1',
          id: 1,
          state: 'fulfilled',
          error: null,
          files: extractionFiles,
        });
      }),

      http.post('/submissions', ({ response }) => {
        return response(200).json({
          submission: { id: 'NSUB000004' },
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

    await clickRadio('Import the submission files from GGS Job ID');
    await fillIn('textarea', '01234567-89ab-cdef-0000-000000000001');
    await click('.card-body button[type="submit"]');

    await waitFor('.list-group-item');

    assert.dom('.list-group-item').exists({ count: 2 });

    await click('button.px-5[type="submit"]');

    // --- Step 3: Metadata ---

    await waitFor('#entriesCount');

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

    await click('#agree-terms');
    await click('button[type="submit"]');

    // --- Step 5: Complete ---

    await waitUntil(() => getRootElement().textContent?.includes('NSUB000004'));

    assert.dom().containsText('NSUB000004', 'MASS ID is displayed');
  });

  test('a rejected extraction shows the error modal instead of leaking an unhandled rejection', async function (assert) {
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
          state: 'rejected',
          error: { id: 'failed_to_fetch', job_id: '01234567-89ab-cdef-0000-000000000001', reason: '404 Not Found' },
          files: [],
        });
      }),
    );

    await visit('/home');

    await click('a[href^="/home/submissions/new"]');

    await clickRadio('Yes, I have determined the nucleotide sequence');
    await click('button[type="submit"]');

    await clickRadio('Import the submission files from DFAST Job ID');
    await fillIn('textarea', '01234567-89ab-cdef-0000-000000000001');
    await click('.card-body button[type="submit"]');

    await waitFor('.modal-body p');

    // A rejected extraction is an expected user error: it must surface in the
    // error modal, not escape as an unhandled rejection (which fails this test).
    assert.dom('.modal-body p').hasText('404 Not Found');
  });

  test('a failed webui upload shows the error modal instead of leaking an unhandled rejection', async function (assert) {
    worker.use(
      http.get('/submissions', ({ response }) => {
        return response(200).json({
          submissions: [],
        });
      }),

      http.get('/submissions/last_submitted', () => {
        return new HttpResponse(null, { status: 404 });
      }),

      // The direct upload to storage fails mid-submission.
      mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => {
        return new HttpResponse(null, { status: 500 });
      }),
    );

    await fillInWebuiSubmission();

    await click('button.px-5[type="submit"]');

    await waitFor('.modal-body p');

    // A failed upload is expected (e.g. a dropped connection): it must surface
    // in the error modal, not escape as an unhandled rejection (which fails
    // this test), and the submission must not proceed.
    assert.dom('.modal-body p').hasText('Error storing "test.ann". Status: 500');
    assert.dom('button.px-5[type="submit"]').exists('stays on the confirm step');
  });

  test('leaving the form during an upload aborts it and takes the backdrop with it', async function (assert) {
    const aborted = watchAbortedRequests();

    let uploadStarted = false;

    try {
      worker.use(
        http.get('/submissions', ({ response }) => {
          return response(200).json({
            submissions: [],
          });
        }),

        http.get('/submissions/last_submitted', () => {
          return new HttpResponse(null, { status: 404 });
        }),

        // The direct upload never answers, so it is still running when the form
        // is left. Leaving aborts it, so nothing arrives afterwards.
        mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => {
          uploadStarted = true;

          return new Promise<Response>(() => {});
        }),
      );

      await fillInWebuiSubmission();

      // Bootstrap appends the backdrop to `<body>`, outside the application's
      // root element, so it has to be looked up in the document. Identify it by
      // what the submit click adds rather than by counting: earlier tests can
      // leave backdrops of their own behind.
      const backdrops = new Set(document.querySelectorAll('.modal-backdrop'));

      await click('button.px-5[type="submit"]');

      const backdrop = [...document.querySelectorAll('.modal-backdrop')].find((el) => !backdrops.has(el));

      assert.ok(backdrop, 'the progress modal covers the page while the upload runs');

      // Leave only once the file is on its way, so that there is a request to
      // abort rather than a checksum still being calculated.
      await waitUntil(() => uploadStarted);

      await visit('/home');

      // An upload left running would go on to report its outcome on the page
      // the user moved to, and submit the application from a destroyed
      // component.
      assert.strictEqual(aborted.count, 1, 'the upload is aborted with the form');

      // Nothing hides the modal when the browser's back button destroys the
      // form mid-upload, so an unclickable overlay would be left over the next
      // page.
      assert.notOk(backdrop?.isConnected, 'the backdrop is removed with the form');
    } finally {
      aborted.restore();
    }
  });

  test('cancelling an upload stops it and stays on the confirm step', async function (assert) {
    const aborted = watchAbortedRequests();

    let uploadStarted = false;

    try {
      worker.use(
        http.get('/submissions', ({ response }) => {
          return response(200).json({
            submissions: [],
          });
        }),

        http.get('/submissions/last_submitted', () => {
          return new HttpResponse(null, { status: 404 });
        }),

        // The direct upload never answers, so it is still running when it is
        // cancelled.
        mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => {
          uploadStarted = true;

          return new Promise<Response>(() => {});
        }),
      );

      await fillInWebuiSubmission();

      await click('button.px-5[type="submit"]');

      // Cancel only once the file is on its way, so that there is a request to
      // abort rather than a checksum still being calculated.
      await waitUntil(() => uploadStarted);

      await click('.modal-footer button');

      assert.strictEqual(aborted.count, 1, 'the upload is aborted');

      // Cancelling is a choice, not a failure, and it leaves the application
      // ready to be submitted again.
      assert.dom('.modal.show').doesNotExist('the progress modal is closed');
      assert.dom('.modal-body p').doesNotExist('cancelling is not reported as an error');
      assert.dom('button.px-5[type="submit"]').exists('stays on the confirm step');

      // Submitting again must not inherit the cancelled upload's signal, which
      // would abort the new one before it starts.
      worker.use(
        mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => new HttpResponse(null, { status: 204 })),

        http.post('/submissions', ({ response }) => {
          return response(200).json({
            submission: { id: 'NSUB000005' },
          });
        }),
      );

      await click('button.px-5[type="submit"]');

      await waitUntil(() => getRootElement().textContent?.includes('NSUB000005'));

      assert.dom().containsText('NSUB000005', 'the application can still be submitted');
    } finally {
      aborted.restore();
    }
  });

  test('cancelling before the upload starts leaves a later attempt alone', async function (assert) {
    const digest = stallDigest();

    try {
      worker.use(
        http.get('/submissions', ({ response }) => {
          return response(200).json({
            submissions: [],
          });
        }),

        http.get('/submissions/last_submitted', () => {
          return new HttpResponse(null, { status: 404 });
        }),

        // The direct upload never answers, so the second attempt is still
        // running when the first one is told about the cancellation.
        mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => new Promise<Response>(() => {})),
      );

      await fillInWebuiSubmission();

      // Cancel while the checksum is still being calculated: this upload only
      // hears about it once the checksum finishes.
      await click('button.px-5[type="submit"]');
      await click('.modal-footer button');

      await click('button.px-5[type="submit"]');

      digest.finish?.('checksum');

      await settled();

      assert.dom('.modal.show').exists('the cancelled upload leaves the running one on screen');
    } finally {
      digest.restore();
    }
  });
});
