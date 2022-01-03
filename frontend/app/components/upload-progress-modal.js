import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import Modal from 'bootstrap/js/src/modal';

export default class UploadProgressModalComponent extends Component {
  @service directUpload;

  @action setModal(element) {
    this.modal = new Modal(element);
  }

  @action show() {
    this.modal.show();
  }

  @action hide() {
    this.modal.hide();
  }
}
