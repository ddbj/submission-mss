import Controller from '@ember/controller';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import 'bootstrap/js/src/dropdown';
import { Modal } from 'bootstrap';

import type IntlService from 'ember-intl/services/intl';

export default class ApplicationController extends Controller {
  @service declare intl: IntlService;

  @tracked error?: Error;
  @tracked locale?: string;

  errorModal?: Modal;

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
  changeLocale(locale: string) {
    this.locale = locale;
  }

  @action
  showErrorModal(error: Error) {
    this.error = error;

    if (this.errorModal) {
      this.errorModal.show();
    } else {
      alert(`Error:
Something went wrong. Please try again later.

${error.message}

Details:
${error.stack}`);
    }
  }
}
