import Service from '@ember/service';
import { guidFor } from '@ember/object/internals';

export default class SequenceFileParser extends Service {
  constructor() {
    super(...arguments);

    this.awaitings = {};

    this.client = new Promise((resolve, reject) => {
      navigator.serviceWorker.register('/workers/sequence-file-parser.js').then(async (registration) => {
        await registration.update();

        const worker = registration.installing || registration.waiting || registration.active;

        function distinguishClientState(fn) {
          switch (worker.state) {
            case 'activated':
              resolve(worker);
              return;
            case 'redundant':
              reject();
              return;
            default:
              fn();
          }
        }

        distinguishClientState(() => {
          worker.addEventListener('statechange', () => {
            distinguishClientState(() => {
              // do nothing
            });
          });
        });
      });
    });

    navigator.serviceWorker.addEventListener('message', (e) => {
      const [err, {guid, ...args}] = e.data;
      const {resolve, reject}      = this.awaitings[guid];

      delete this.awaitings[guid];

      if (err) {
        reject(err);
      } else {
        resolve(args);
      }
    });
  }

  async parse(file) {
    const client = await this.client;
    const guid   = guidFor({});

    return new Promise((resolve, reject) => {
      this.awaitings[guid] = {resolve, reject};

      client.postMessage({guid, file});
    });
  }
}
