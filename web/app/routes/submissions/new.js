import Route from '@ember/routing/route';

import Submission from 'mssform/models/submission';

export default class SubmissionsNewRoute extends Route {
  model() {
    return new Submission();
  }
}
