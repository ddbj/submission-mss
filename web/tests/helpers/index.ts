import {
  type SetupTestOptions,
  setupApplicationTest as upstreamSetupApplicationTest,
  setupRenderingTest as upstreamSetupRenderingTest,
  setupTest as upstreamSetupTest,
} from 'ember-qunit';

import { worker } from '../msw/worker';

function setupApplicationTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupApplicationTest(hooks, options);

  hooks.afterEach(() => {
    worker.resetHandlers();
  });
}

function setupRenderingTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupRenderingTest(hooks, options);
}

function setupTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupTest(hooks, options);
}

export { setupApplicationTest, setupRenderingTest, setupTest };
