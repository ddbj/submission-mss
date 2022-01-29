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

class Navigation {
  steps = [
    'prerequisite',
    'files',
    'metadata2',
    'confirm',
    'submit'
  ];

  @tracked stepIndex = 0;

  get currentStep() {
    return this.steps[this.stepIndex];
  }

  @action isCurrent(step) {
    return this.currentStep === step;
  }

  @action isFollowing(step) {
    return this.stepIndex < this.steps.indexOf(step);
  }

  @action goNext() {
    this.stepIndex = Math.min(this.stepIndex + 1, this.steps.length);
  }

  @action goPrev() {
    this.stepIndex = Math.max(0, this.stepIndex - 1);
  }
}

export default class SubmissionFormComponent extends Component {
  @service router;
  @service session;

  state = new State();
  nav   = new Navigation();
}
