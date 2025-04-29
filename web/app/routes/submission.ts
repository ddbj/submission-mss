import Route from '@ember/routing/route';
import { service } from '@ember/service';

import RequestService from 'mssform/services/request';

export default class SubmissionRoute extends Route {
  @service declare request: RequestService;

  async model({ id }: { id: string }) {
    const res = await this.request.fetch(`/submissions/${id}`);

    return ((await res.json()) as { submission: unknown }).submission;
  }
}
