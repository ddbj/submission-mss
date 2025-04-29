import Component from '@glimmer/component';
import { action } from '@ember/object';

import OtherPerson from 'mssform/models/other-person';

import type Submission from 'mssform/models/submission';

interface Signature {
  Args: {
    model: Submission;
  };
}

export default class SubmissionFormMetadataComponent extends Component<Signature> {
  @action addOtherPerson() {
    const { model } = this.args;

    model.otherPeople = [...model.otherPeople, new OtherPerson()];
  }

  @action removeOtherPerson(person: OtherPerson) {
    const { model } = this.args;

    model.otherPeople = model.otherPeople.filter((p) => p !== person);
  }
}
