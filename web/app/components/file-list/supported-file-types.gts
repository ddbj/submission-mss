import Component from '@glimmer/component';
import { t } from 'ember-intl';

import { AnnotationFile, SequenceFile } from 'mssform/models/submission-file';

export default class SupportedFileTypes extends Component {
  extensions = {
    annotation: AnnotationFile.extensions,
    sequence: SequenceFile.extensions,
  };

  <template>
    <dl>
      <dt>{{t "file-list.supported-file-types.annotation-file"}}</dt>
      <dd>
        <ul class="list-inline mb-0">
          {{#each this.extensions.annotation as |extension|}}
            <li class="list-inline-item">
              <code>{{extension}}</code>
            </li>
          {{/each}}
        </ul>
      </dd>

      <dt>{{t "file-list.supported-file-types.sequence-file"}}</dt>
      <dd>
        <ul class="list-inline mb-0">
          {{#each this.extensions.sequence as |extension|}}
            <li class="list-inline-item">
              <code>{{extension}}</code>
            </li>
          {{/each}}
        </ul>
      </dd>
    </dl>
  </template>
}
