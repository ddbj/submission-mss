import Component from '@glimmer/component';
import { action } from '@ember/object';
import { importSync } from '@embroider/macros';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class SubmissionFormComponent extends Component {
  @service router;

  state = new State();
  nav = new Navigation();

  get component() {
    return importSync(`./submission-form/${this.nav.currentStep}`).default;
  }
}

class State {
  @tracked maybeTpa = null;
  @tracked files = [];
}

class Navigation {
  steps = ['prerequisite', 'files', 'metadata', 'confirm', 'complete'];

  @tracked stepIndex = 0;

  get currentStep() {
    return this.steps[this.stepIndex];
  }

  get prevStep() {
    const i = Math.max(0, this.stepIndex - 1);

    return this.steps[i];
  }

  get nextStep() {
    const i = Math.min(this.stepIndex + 1, this.steps.length);

    return this.steps[i];
  }

  @action goNext() {
    this.gotoStep(this.nextStep);
  }

  @action goPrev() {
    this.gotoStep(this.prevStep);
  }

  @action gotoStep(step) {
    if (this.currentStep === 'complete') return;
    if (step === this.currentStep) return;
    if (this.isFollowing(step) && step !== this.nextStep) return;

    this.stepIndex = this.steps.indexOf(step);

    document.documentElement.scrollTop = 0;
  }

  @action isFollowing(step) {
    return this.stepIndex < this.steps.indexOf(step);
  }
}
