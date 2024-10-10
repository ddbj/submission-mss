import Controller from '@ember/controller';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import 'bootstrap/js/src/dropdown';
import { Modal } from 'bootstrap';

export default class ApplicationController extends Controller {
  @service intl;

  @tracked error;
  @tracked locale;

  queryParams = ['locale'];

  setErrorModal = modifier((el) => {
    this.errorModal = new Modal(el);

    const handler = () => {
      this.error = undefined;
    };

    el.addEventListener('hidden.bs.modal', handler);

    return () => {
      el.removeEventListener('hidden.bs.modal', handler);
    };
  });

  @action
  changeLocale(locale) {
    this.locale = locale;
  }

  @action
  showErrorModal(error) {
    this.error = error;

    if (this.errorModal) {
      this.errorModal.show();
    } else {
      const details = error instanceof Error ? error.stack : JSON.stringify(error, null, 2);

      alert(`Error:
Something went wrong. Please try again later.

${error}

Details:
${details}`);
    }
  }
}
