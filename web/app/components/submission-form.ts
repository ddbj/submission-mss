import Component from '@glimmer/component';
import { action } from '@ember/object';
import { importSync } from '@embroider/macros';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import type Router from '@ember/routing/router';
import type SubmissionFile from 'mssform/models/submission-file';

type Step = (typeof Navigation.prototype.steps)[number];

export default class SubmissionFormComponent extends Component {
  @service declare router: Router;

  state = new State();
  nav = new Navigation();

  get component() {
    return (importSync(`./submission-form/${this.nav.currentStep}`) as { default: Component }).default;
  }

  @action
  stepNavLinkClass(step: Step) {
    return step === this.nav.currentStep
      ? 'active'
      : this.nav.currentStep === 'complete'
        ? 'disabled'
        : this.nav.isFollowing(step)
          ? 'disabled'
          : null;
  }
}

export class State {
  @tracked maybeTpa?: boolean;
  @tracked files: SubmissionFile[] = [];
}

export class Navigation {
  readonly steps = ['prerequisite', 'files', 'metadata', 'confirm', 'complete'] as const;

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
    this.gotoStep(this.nextStep!);
  }

  @action goPrev() {
    this.gotoStep(this.prevStep!);
  }

  @action gotoStep(step: Step) {
    if (this.currentStep === 'complete') return;
    if (step === this.currentStep) return;
    if (this.isFollowing(step) && step !== this.nextStep) return;

    this.stepIndex = this.steps.indexOf(step);

    document.documentElement.scrollTop = 0;
  }

  @action isFollowing(step: Step) {
    return this.stepIndex < this.steps.indexOf(step);
  }
}
