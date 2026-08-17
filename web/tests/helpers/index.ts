import {
  type SetupTestOptions,
  setupApplicationTest as upstreamSetupApplicationTest,
  setupRenderingTest as upstreamSetupRenderingTest,
  setupTest as upstreamSetupTest,
} from 'ember-qunit';

import { worker } from '../msw/worker';

// Drops the handlers a test installed with `worker.use`, so they cannot answer
// for the tests that follow.
function resetHandlers(hooks: NestedHooks) {
  hooks.afterEach(() => {
    worker.resetHandlers();
  });
}

// Bootstrap puts a modal's backdrop and scroll lock on `<body>`, out of Ember's
// reach, and only takes them down when the modal is hidden. Registered before
// the application's own teardown so that it runs after it, this says whether
// the application cleaned up after itself.
function assertNothingLeftOnBody(hooks: NestedHooks) {
  hooks.afterEach(function (assert) {
    assert.dom('.modal-backdrop', document.body).doesNotExist('the application leaves no backdrop behind');
    assert.dom(document.body).doesNotHaveClass('modal-open');

    // Cleaned up either way, so that a leak fails the test that made it rather
    // than every test that runs after it.
    for (const backdrop of document.body.querySelectorAll('.modal-backdrop')) {
      backdrop.remove();
    }

    document.body.classList.remove('modal-open');
    document.body.style.removeProperty('overflow');
    document.body.style.removeProperty('padding-right');
  });
}

function setupApplicationTest(hooks: NestedHooks, options?: SetupTestOptions) {
  assertNothingLeftOnBody(hooks);
  upstreamSetupApplicationTest(hooks, options);
  resetHandlers(hooks);
}

function setupRenderingTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupRenderingTest(hooks, options);
  resetHandlers(hooks);
}

function setupTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupTest(hooks, options);
  resetHandlers(hooks);
}

export { setupApplicationTest, setupRenderingTest, setupTest };
