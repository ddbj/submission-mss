import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import { DirectUpload } from '@rails/activestorage';
import { task } from 'ember-concurrency';

const url = '/rails/active_storage/direct_uploads';

export default class DirectUploadComponent extends Component {
  @tracked progress = 0;

  @task *uploadFiles(files) {
    for (const file of Array.from(files)) {
      yield this.uploadFile.perform(file);
    }
  }

  @task *uploadFile(file) {
    this.progress = 0;

    // Since service switching is disabled on the server side, there is no need to send these parameters.
    // See config/initializers/active_storage_direct_uploads_controller_monkey.rb.
    const serviceName    = null;
    const attachmentName = null;

    const upload = new DirectUpload(file, url, serviceName, attachmentName, {
      directUploadWillStoreFileWithXHR(xhr) {
        xhr.upload.addEventListener('progress', ({loaded, total}) => {
          this.progress = loaded / total;
        });
      }
    });

    const blob = yield new Promise((resolve, reject) => {
      upload.create((err, blob) => {
        if (err) {
          reject(err);
        } else {
          resolve(blob);
        }
      });
    });

    this.args.didUpload?.(blob, file);
  }
}
