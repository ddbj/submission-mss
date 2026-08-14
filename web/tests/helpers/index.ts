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

function setupApplicationTest(hooks: NestedHooks, options?: SetupTestOptions) {
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
