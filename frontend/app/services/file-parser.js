import Service from '@ember/service';
import { guidFor } from '@ember/object/internals';

export default class FileParserService extends Service {
  workers = {};
  running = {};

  workerFor(type) {
    const cached = this.workers[type];

    if (cached) { return cached; }

    const worker = this.workers[type] = new Worker(`/workers/${type}-file-parser.js`);

    worker.addEventListener('message', (e) => {
      const [err, [id, payload]] = e.data;
      const {resolve, reject}      = this.running[id];

      delete this.running[id];

      if (err) {
        reject(err);
      } else {
        resolve(payload);
      }
    });

    return worker;
  }

  parse(type, file) {
    const worker = this.workerFor(type);
    const id     = guidFor({});

    return new Promise((resolve, reject) => {
      this.running[id] = {resolve, reject};

      worker.postMessage([id, file]);
    });
  }
}
