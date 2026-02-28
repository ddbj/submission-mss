import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

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

    this.setMessage(error);
    this.setDetails(error);
  }

  setMessage(error: Error & { content?: unknown; statusText?: string }) {
    if (error.content) {
      const content = error.content as { error?: string };

      this.message = content.error ? content.error : JSON.stringify(content);
    } else if (error.statusText) {
      this.message = error.statusText;
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
