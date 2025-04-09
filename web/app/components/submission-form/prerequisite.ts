import Component from '@glimmer/component';
import { action } from '@ember/object';

import type Submission from 'mssform/models/submission';
import type { State } from 'mssform/components/submission-form';

interface Signature {
  Args: {
    model: Submission;
    state: State;
  };
}

export default class SubmissionFormPrerequisiteComponent extends Component<Signature> {
  @action setMaybeTpa(val: boolean) {
    const { model, state } = this.args;

    state.maybeTpa = val;
    model.tpa = val ? undefined : false;
  }
}
