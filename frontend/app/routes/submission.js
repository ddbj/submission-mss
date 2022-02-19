import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SubmissionRoute extends Route {
  @service store;

  model({id}) {
    return {id};
  }
}
