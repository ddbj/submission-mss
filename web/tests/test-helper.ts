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

      if (
        url.pathname.startsWith('/socket.io/') ||
        url.pathname.startsWith('/workers/') ||
        url.pathname === '/favicon.ico' ||
        url.hostname === 'cdn.jsdelivr.net'
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
