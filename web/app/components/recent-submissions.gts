import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { formatDate } from 'ember-intl';
import { gt } from 'ember-truth-helpers';
import { task } from 'ember-concurrency';

import type { components, paths } from 'schema/openapi';
import type Owner from '@ember/owner';
import type RequestManager from '@ember-data/request';

type Submission = components['schemas']['Submission'];

function dfastJobIds(submission: Submission): string[] {
  return submission.uploads[0]?.dfast_job_ids ?? [];
}

function take<T>(n: number, arr: T[]): T[] {
  return arr.slice(0, n);
}

function drop<T>(n: number, arr: T[]): T[] {
  return arr.slice(n);
}

export default class RecentSubmissions extends Component {
  @service declare requestManager: RequestManager;

  @tracked submissions: Submission[] = [];

  get sortedSubmissions() {
    return [...this.submissions].sort((a, b) => b.id.localeCompare(a.id));
  }

  loadSubmissions = task(async () => {
    type SubmissionIndex = paths['/submissions']['get']['responses']['200']['content']['application/json'];

    const { content } = await this.requestManager.request<SubmissionIndex>({
      url: '/submissions',
    });

    this.submissions = content.submissions;
  });

  constructor(owner: Owner, args: Record<string, never>) {
    super(owner, args);

    void this.loadSubmissions.perform();
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
          {{#each this.sortedSubmissions as |submission|}}
            <tr>
              <td>
                <LinkTo @route="submission" @model={{submission}}>{{submission.id}}</LinkTo>
              </td>

              <td>
                {{formatDate submission.created_at}}
              </td>

              <td>
                {{#let (dfastJobIds submission) as |jobIds|}}
                  <ul class="list-unstyled m-0">
                    {{#each (take 3 jobIds) as |jobId|}}
                      <li><code>{{jobId}}</code></li>
                    {{/each}}
                  </ul>

                  {{#if (gt jobIds.length 3)}}
                    <details>
                      <summary>View all</summary>

                      <ul class="list-unstyled m-0">
                        {{#each (drop 3 jobIds) as |jobId|}}
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
