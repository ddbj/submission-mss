import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type RequestService from 'mssform/services/request';

export default class SubmissionRoute extends Route {
  @service declare request: RequestService;

  async model({ id }: { id: string }) {
    const json = (await this.request.fetch(`/submissions/${id}`).then((res) => res.json())) as { submission: unknown };

    return json.submission;
  }
}
