import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import Modal from 'bootstrap/js/src/modal';
import { DirectUpload } from '@rails/activestorage';

const url = '/rails/active_storage/direct_uploads';

export default class SubmissionFormComponent extends Component {
  @service appauth;
  @service intl;
  @service session;

  @tracked determinedByOwnStudy = null;
  @tracked fileIsPrepared       = null;
  @tracked files                = A([]);
  @tracked confirmed            = false;
  @tracked dragOver             = false;

  fileInputElement     = null;
  progressModalElement = null;

  get dataTypes() {
    const {dfast} = this.args.model;

    return dfast ? ['wgs', 'complete_genome', 'mag', 'wgs_version_up']
                 : ['wgs', 'complete_genome', 'mag', 'sag', 'wgs_version_up', 'tls', 'htg', 'tsa', 'htc', 'est', 'dna', 'rna', 'other'];
  }

  @action setProgressModal(element) {
    this.progressModal = Modal.getOrCreateInstance(element);
  }

  @action setDeterminedByOwnStudy(val) {
    this.determinedByOwnStudy = val;

    this.args.model.tpa = val ? false : null;
  }

  @action setDfast(val) {
    this.args.model.dfast = val;

    this.setDataType(null);
  }

  @action setDataType(val) {
    this.args.model.dataType          = val;
    this.args.model.dataTypeOtherText = null;
    this.args.model.accessionNumber   = null;
  }

  @action selectFiles() {
    this.fileInputElement.click();
  }

  @action addFiles(files) {
    this.files.pushObjects(Array.from(files));

    this.dragOver = false;
  }

  @action removeFile(file) {
    this.files.removeObject(file);
  }

  @action cancelSubmit() {
    this.progressModal.hide();
  }

  get totalSize() {
    return this.files.reduce((acc, {size}) => acc + size, 0);
  }

  @tracked currentFile;
  @tracked isPreparing;
  @tracked totalUploadedFilesSize;
  @tracked currentUploadedFileSize;

  get uploadPercentage() {
    return Math.floor((this.totalUploadedFilesSize + this.currentUploadedFileSize) / this.totalSize * 100);
  }

  @action async submit() {
    this.currentFile             = null;
    this.isPreparing             = false;
    this.totalUploadedFilesSize  = 0;
    this.currentUploadedFileSize = 0;

    this.progressModal.show();

    this.args.model.files = await uploadFiles(this.fileIsPrepared ? this.files.toArray() : [], {
      init: (file) => {
        this.currentFile = file;
        this.isPreparing = true;
      },

      onLoadStart: () => {
        this.isPreparing = false;
      },

      onProgress: ({loaded}) => {
        this.currentUploadedFileSize = loaded;
      },

      onLoad: ({total}) => {
        this.totalUploadedFilesSize += total;
        this.currentUploadedFileSize = 0;
      }
    });

    await this.session.authenticate('authenticator:appauth');

    const res = await fetch('/api/submissions', {
      method: 'POST',

      headers: {
        Authorization: `Bearer ${this.session.data.authenticated.id_token}`,
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        submission: this.args.model.toPayload()
      })
    });

    if (!res.ok) {
      throw new Error(res.statusText);
    }

    console.log(await res.json());
  }
}

async function uploadFiles(files, {init, onLoadStart, onProgress, onLoad}) {
  const signedIds = [];

  for (const file of files) {
    const {signed_id} = await uploadFile(file, {init, onLoadStart, onProgress, onLoad});

    signedIds.push(signed_id);
  }

  return signedIds;
}

function uploadFile(file, {init, onLoadStart, onProgress, onLoad}) {
  // Since service switching is disabled on the server side, there is no need to send these parameters.
  // See config/initializers/active_storage_direct_uploads_controller_monkey.rb.
  const serviceName    = null;
  const attachmentName = null;

  init(file);

  const upload = new DirectUpload(file, url, serviceName, attachmentName, {
    directUploadWillStoreFileWithXHR(xhr) {
      xhr.upload.addEventListener('loadstart', onLoadStart);
      xhr.upload.addEventListener('progress',  onProgress);
      xhr.upload.addEventListener('load',      onLoad);
    }
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
