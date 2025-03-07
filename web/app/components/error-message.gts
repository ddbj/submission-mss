import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import { FetchError } from 'mssform/services/request';

import type Owner from '@ember/owner';

export interface Signature {
  Args: {
    error: Error;
  };
}

export default class ErrorMessageComponent extends Component<Signature> {
  @tracked message?: string;
  @tracked details?: string;

  constructor(owner: Owner, args: Signature['Args']) {
    super(owner, args);

    const { error } = this.args;

    void this.setMessage(error);
    this.setDetails(error);
  }

  async setMessage(error: Error) {
    if (error instanceof FetchError) {
      const { response } = error;

      try {
        const json = (await response.json()) as { error?: string };

        this.message = json.error ? json.error : JSON.stringify(json);
      } catch (e) {
        if (e instanceof SyntaxError) {
          this.message = await response.text();
        } else {
          this.message = error.message;
        }
      }
    } else {
      this.message = error.message;
    }
  }

  setDetails(error: Error) {
    this.details = error.stack;
  }

  <template>
    <p>{{this.message}}</p>

    <details>
      <summary>Details</summary>
      <pre class="text-bg-dark text-pre-wrap p-3"><code>{{this.details}}</code></pre>
    </details>
  </template>
}

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry {
    ErrorMessage: typeof ErrorMessageComponent;
  }
}
