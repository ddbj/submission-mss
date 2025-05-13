import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { get } from '@ember/helper';

import drop from 'ember-composable-helpers/helpers/drop';
import sortBy from 'ember-composable-helpers/helpers/sort-by';
import take from 'ember-composable-helpers/helpers/take';
import { formatDate } from 'ember-intl';
import { gt } from 'ember-truth-helpers';
import { task } from 'ember-concurrency';

export default class RecentSubmissions extends Component {
  @service request;

  @tracked submissions;

  loadSubmissions = task(async () => {
    const res = await this.request.fetch('/submissions');

    this.submissions = (await res.json()).submissions;
  });

  constructor() {
    super(...arguments);

    this.loadSubmissions.perform();
  }

  <template>
    {{#if this.loadSubmissions.isRunning}}
      <p>Loading...</p>
    {{else}}
      <table class="table">
        <thead>
          <tr>
            <th>Mass ID</th>
            <th>Submission Date</th>
            <th>DFAST Job IDs</th>
            <th>Status</th>
            <th>Accession</th>
          </tr>
        </thead>

        <tbody>
          {{#each (sortBy "id:desc" this.submissions) as |submission|}}
            <tr>
              <td>
                <LinkTo @route="submission" @model={{submission}}>{{submission.id}}</LinkTo>
              </td>

              <td>
                {{formatDate submission.created_at}}
              </td>

              <td>
                {{#let (get submission.uploads "0") as |upload|}}
                  <ul class="list-unstyled m-0">
                    {{#each (take 3 upload.dfast_job_ids) as |jobId|}}
                      <li><code>{{jobId}}</code></li>
                    {{/each}}
                  </ul>

                  {{#if (gt submission.dfast_job_ids.length 3)}}
                    <details>
                      <summary>View all</summary>

                      <ul class="list-unstyled m-0">
                        {{#each (drop 3 upload.dfast_job_ids) as |jobId|}}
                          <li><code>{{jobId}}</code></li>
                        {{/each}}
                      </ul>
                    </details>
                  {{/if}}
                {{/let}}
              </td>

              <td>
                {{submission.status}}
              </td>

              <td>
                <ul class="list-unstyled m-0">
                  {{#each (take 3 submission.accessions) as |accession|}}
                    <li><code>{{accession}}</code></li>
                  {{/each}}
                </ul>

                {{#if (gt submission.accessions.length 3)}}
                  <details>
                    <summary>View all</summary>

                    <ul class="list-unstyled m-0">
                      {{#each (drop 3 submission.accessions) as |accession|}}
                        <li><code>{{accession}}</code></li>
                      {{/each}}
                    </ul>
                  </details>
                {{/if}}
              </td>
            </tr>
          {{/each}}
        </tbody>
      </table>
    {{/if}}
  </template>
}
