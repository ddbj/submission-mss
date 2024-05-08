import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormPrerequisiteComponent extends Component {
  @action setMaybeTpa(val) {
    const {model, state} = this.args;

    state.maybeTpa = val;
    model.tpa      = val ? null : false;
  }
}
