import Component from '@glimmer/component';
import { action } from '@ember/object';

import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormPrerequisiteComponent extends Component<Signature> {
  @action setMaybeTpa(val: boolean) {
    this.args.state.maybeTpa = val;
    this.args.model.tpa = val ? null : false;
  }
}
