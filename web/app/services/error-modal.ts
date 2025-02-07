import Service from '@ember/service';
import { getOwner } from '@ember/owner';

import type ApplicationController from 'mssform/controllers/application';

export default class ErrorModalService extends Service {
  show(error: Error) {
    const controller = getOwner(this)!.lookup('controller:application') as ApplicationController;

    controller.showErrorModal(error);

    throw error;
  }
}
