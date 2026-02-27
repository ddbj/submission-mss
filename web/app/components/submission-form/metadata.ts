import Component from '@glimmer/component';
import { action } from '@ember/object';

import OtherPerson from 'mssform/models/other-person';

import type Submission from 'mssform/models/submission';
import type { Navigation } from 'mssform/components/submission-form';

export interface Signature {
  Args: {
    model: Submission;
    nav: Navigation;
  };
}

export default class SubmissionFormMetadataComponent extends Component<Signature> {
  @action addOtherPerson() {
    this.args.model.otherPeople = [...this.args.model.otherPeople, new OtherPerson()];
  }

  @action removeOtherPerson(person: OtherPerson) {
    this.args.model.otherPeople = this.args.model.otherPeople.filter((p) => p !== person);
  }
}
