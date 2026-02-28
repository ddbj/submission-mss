import Route from '@ember/routing/route';
import { service } from '@ember/service';

import type { paths } from 'schema/openapi';
import type RequestManager from '@ember-data/request';

type ShowSubmission = paths['/submissions/{mass_id}']['get']['responses']['200']['content']['application/json'];

export default class SubmissionRoute extends Route {
  @service declare requestManager: RequestManager;

  async model({ id }: { id: string }) {
    const { content } = await this.requestManager.request<ShowSubmission>({
      url: `/submissions/${id}`,
    });

    return content.submission;
  }
}
