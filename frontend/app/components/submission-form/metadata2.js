import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormMetadataComponent extends Component {
  @action setReleaseImmediately(val) {
    const {model, state} = this.args;

    state.releaseImmediately = val;

    if (val) {
      model.holdDate = null;
    }
  }

  @action addOtherPerson() {
    this.args.model.otherPeople.createRecord();
  }

  @action removeOtherPerson(person) {
    person.destroyRecord();
  }
}
