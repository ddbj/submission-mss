import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

class State {
  @tracked determinedByOwnStudy = null;
  @tracked submissionFileType   = null;
  @tracked files                = A([]);
  @tracked releaseImmediately   = true;
}

export default class SubmissionFormComponent extends Component {
  @service router;
  @service session;

  state = new State();

  steps = [
    'prerequisite',
    'files',
    'metadata',
    'confirm',
    'submit'
  ];

  @tracked currentStepIndex = 0;

  get currentStep() {
    return this.steps[this.currentStepIndex];
  }

  @action goNextStep() {
    this.currentStepIndex = Math.min(this.currentStepIndex + 1, this.steps.length);
  }

  @action goPrevStep() {
    this.currentStepIndex = Math.max(0, this.currentStepIndex - 1);
  }
}
