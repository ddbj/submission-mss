import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { DirectUpload } from '@rails/activestorage';

const url = '/rails/active_storage/direct_uploads';

export default class SubmissionFormComponent extends Component {
  @service session;
  @service appauth;

  @tracked files = A([]);

  @action addFiles({ target }) {
    this.files.pushObjects(Array.from(target.files));

    target.value = '';
  }

  @action removeFile(file) {
    this.files.removeObject(file);
  }

  @action async submit(e) {
    e.preventDefault();

    const blobs = await Promise.all(
      this.files.map((file) => {
        return uploadFile(file, (progress) => console.log(file, progress));
      })
    );

    const tokenRes = await this.appauth.makeTokenRequestFromRefreshToken({
      redirectUrl: new URL('/auth/callback', location),
      refreshToken: this.session.data.authenticated.refreshToken
    });

    console.log(tokenRes);

    const res = await fetch('/api/submissions', {
      method: 'POST',

      headers: {
        Authorization: `Bearer ${tokenRes.idToken}`,
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        submission: {
          files: blobs.map(({ signed_id }) => signed_id),
        },
      }),
    });

    if (!res.ok) {
      throw new Error(res.statusText);
    }

    console.log(await res.json());
  }
}

function uploadFile(file, onProgress) {
  // Since service switching is disabled on the server side, there is no need to send these parameters.
  // See config/initializers/active_storage_direct_uploads_controller_monkey.rb.
  const serviceName = null;
  const attachmentName = null;

  const upload = new DirectUpload(file, url, serviceName, attachmentName, {
    directUploadWillStoreFileWithXHR(xhr) {
      xhr.upload.addEventListener('progress', onProgress);
    },
  });

  return new Promise((resolve, reject) => {
    upload.create((err, blob) => {
      if (err) {
        reject(err);
      } else {
        resolve(blob);
      }
    });
  });
}
