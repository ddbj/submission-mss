import '@warp-drive/ember/install';
import Application from 'mssform/app';
import config from 'mssform/config/environment';
import * as QUnit from 'qunit';
import { setApplication } from '@ember/test-helpers';
import { setup } from 'qunit-dom';
import { start as qunitStart, setupEmberOnerrorValidation } from 'ember-qunit';

import { worker } from './msw/worker';

export async function start() {
  await worker.start({
    quiet: true,

    onUnhandledRequest(request, print) {
      const url = new URL(request.url);

      // The app's own code is served, never mocked: out of `/assets/` in a
      // build, and out of the module graph the dev server runs from.
      if (
        url.pathname.startsWith('/socket.io/') ||
        url.pathname.startsWith('/assets/') ||
        url.pathname.startsWith('/workers/') ||
        url.pathname.startsWith('/node_modules/') ||
        url.pathname === '/favicon.ico'
      ) {
        return;
      }

      print.warning();
    },
  });

  setApplication(Application.create(config.APP));

  setup(QUnit.assert);
  setupEmberOnerrorValidation();
  qunitStart();
}
