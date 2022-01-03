import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import Modal from 'bootstrap/js/src/modal';

export default class UploadProgressModalComponent extends Component {
  @tracked directUpload;

  @action setModal(element) {
    this.modal = new Modal(element);
  }

  @action show(directUpload) {
    this.directUpload = directUpload;

    this.modal.show();
  }

  @action hide() {
    this.modal.hide();
  }
}
