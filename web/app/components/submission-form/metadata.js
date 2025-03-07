import Component from '@glimmer/component';
import { action } from '@ember/object';

import OtherPerson from 'mssform/models/other-person';

export default class SubmissionFormMetadataComponent extends Component {
  @action addOtherPerson() {
    const { model } = this.args;

    model.otherPeople = [...model.otherPeople, new OtherPerson()];
  }

  @action removeOtherPerson(person) {
    const { model } = this.args;

    model.otherPeople = model.otherPeople.filter((p) => p !== person);
  }
}
