import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SubmissionRoute extends Route {
  @service request;

  async model({ id }) {
    return (await this.request.fetch(`/submissions/${id}`).then((res) => res.json())).submission;
  }
}
