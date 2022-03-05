import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SubmissionRoute extends Route {
  @service router;
  @service session;

  async model({id}) {
    await this.session.renewToken();

    const res = await fetch(`/api/submissions/${id}`, {
      method:  'HEAD',
      headers: this.session.authorizationHeader
    });

    if (!res.ok) {
      this.router.transitionTo('index');
    }

    return {id};
  }
}
