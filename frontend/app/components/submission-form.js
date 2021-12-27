import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormComponent extends Component {
  @action
  didUpload(blob, file) {
    debugger
  }
}
