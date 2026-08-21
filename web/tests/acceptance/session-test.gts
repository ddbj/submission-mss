import { module, test } from 'qunit';
import { visit, click, currentURL } from '@ember/test-helpers';
import { setupApplicationTest } from 'mssform/tests/helpers';
import { setupAuthentication } from 'mssform/tests/helpers/setup-auth';

import { HttpResponse } from 'msw';
import { http } from '../msw/http';
import { worker } from '../msw/worker';

module('Acceptance | session', function (hooks) {
  setupApplicationTest(hooks);

  module('signed in', function (hooks) {
    setupAuthentication(hooks);

    hooks.beforeEach(function () {
      worker.use(
        http.get('/submissions', ({ response }) => {
          return response(200).json({ submissions: [] });
        }),
      );
    });

    test('the home page is theirs to visit', async function (assert) {
      await visit('/home');

      assert.strictEqual(currentURL()?.split('?')[0], '/home');
    });

    test('signing out asks the server to discard the session', async function (assert) {
      let signedOut = false;

      worker.use(
        http.delete('/session', () => {
          signedOut = true;

          return new HttpResponse(null, { status: 204 });
        }),
      );

      await visit('/home');
      await click('button.btn-link');

      // The credential is a cookie the application cannot reach, so the only
      // way to be rid of it is to ask.
      assert.true(signedOut, 'the session is discarded where it lives');
      assert.strictEqual(currentURL()?.split('?')[0], '/');
    });

    test('signing out of a session the server has already forgotten', async function (assert) {
      await visit('/home');

      worker.use(
        http.delete('/session', ({ response }) => {
          return response(401).empty();
        }),
      );

      await click('button.btn-link');

      // Being told there was nothing to end is the outcome that was asked for,
      // not something to put in front of the visitor.
      assert.strictEqual(currentURL()?.split('?')[0], '/');
      assert.dom('.modal.show').doesNotExist('no error is raised over it');
    });
  });

  module('signed out', function () {
    test('the home page sends them to the way in', async function (assert) {
      await visit('/home');

      assert.strictEqual(currentURL()?.split('?')[0], '/');
      assert.dom('form[method="POST"]').exists('the way in is offered');
    });
  });
});
