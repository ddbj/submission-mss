import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormMetadataComponent extends Component {
  @action addOtherPerson() {
    this.args.model.otherPeople.createRecord();
  }

  @action removeOtherPerson(person) {
    person.destroyRecord();
  }
}
