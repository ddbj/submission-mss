import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormPrerequisiteComponent extends Component {
  @action setDeterminedByOwnStudy(val) {
    const {model, state} = this.args;

    state.determinedByOwnStudy = val;

    model.tpa = val ? false : null;
  }
}
