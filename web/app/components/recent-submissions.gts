import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import { formatDate, t } from 'ember-intl';
import { task } from 'ember-concurrency';

import type { components, paths } from 'schema/openapi';
import type Owner from '@ember/owner';
import type { RequestManager } from '@warp-drive/core';

type Submission = components['schemas']['Submission'];

function submissionJobIds(submission: Submission): string[] {
  return submission.uploads[0]?.job_ids ?? [];
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
      <p>{{t "recent-submissions.loading"}}</p>
    {{else}}
      <table class="table">
        <thead>
          <tr>
            <th>{{t "recent-submissions.mass-id"}}</th>
            <th>{{t "recent-submissions.submitted-at"}}</th>
            <th>{{t "recent-submissions.job-ids"}}</th>
            <th>{{t "recent-submissions.status"}}</th>
            <th>{{t "recent-submissions.accessions"}}</th>
          </tr>
        </thead>

        <tbody>
          {{#each this.submissions as |submission|}}
            <tr>
              <td>
                <LinkTo @route="submission" @model={{submission}}>{{submission.id}}</LinkTo>
              </td>

              <td>
                {{formatDate submission.created_at}}
              </td>

              <td>
                {{#let (submissionJobIds submission) as |jobIds|}}
                  <ul class="list-unstyled m-0">
                    {{#each (take 3 jobIds) as |jobId|}}
                      <li><code>{{jobId}}</code></li>
                    {{/each}}
                  </ul>

                  {{#if (gt jobIds.length 3)}}
                    <details>
                      <summary>{{t "recent-submissions.view-all"}}</summary>

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
                {{! As the curators write it in the working list: there is no set
                    of values to translate. }}
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
                    <summary>{{t "recent-submissions.view-all"}}</summary>

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
