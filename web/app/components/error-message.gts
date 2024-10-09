import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import { FetchFailed } from 'mssform/utils/safe-fetch';

export interface Signature {
  Args: {
    error: Error | object;
  };
}

export default class ErrorMessageComponent extends Component<Signature> {
  @tracked message?: string;
  @tracked details?: string;

  constructor(owner: unknown, args: Signature['Args']) {
    super(owner, args);

    const { error } = this.args;

    this.setMessage(error);
    this.setDetails(error);
  }

  async setMessage(error: Signature['Args']['error']) {
    if (error instanceof FetchFailed) {
      const { response } = error;

      try {
        const json = await response.json();

        this.message = json.error ? json.error : JSON.stringify(json);
      } catch (e) {
        if (e instanceof SyntaxError) {
          this.message = await response.text();
        } else {
          this.message = error.toString();
        }
      }
    } else if (error instanceof Error) {
      this.message = error.message;
    } else {
      this.message = error.toString();
    }
  }

  setDetails(error: Signature['Args']['error']) {
    if (error instanceof Error) {
      this.details = error.stack;
    } else {
      this.details = JSON.stringify(error, null, 2);
    }
  }

  <template>
    <p>{{this.message}}</p>

    <details>
      <summary>Details</summary>
      <pre class='text-bg-dark text-pre-wrap p-3'><code>{{this.details}}</code></pre>
    </details>
  </template>
}

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry {
    ErrorMessage: typeof ErrorMessageComponent;
  }
}
