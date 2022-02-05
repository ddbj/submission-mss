import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

import FileSet from 'mssform-web/models/file-set';

export default class SubmissionFormComponent extends Component {
  @service router;
  @service session;

  nav = new Navigation();

  constructor(owner) {
    super(...arguments);

    this.state = new State({owner});
  }
}

class State {
  @tracked determinedByOwnStudy = null;
  @tracked submissionFileType   = 'dfast'; // FIXME null
  @tracked fileSet              = new FileSet({owner: this.owner});
  @tracked releaseImmediately   = true;

  owner;

  constructor({owner}) {
    this.owner = owner;
  }
}

class Navigation {
  steps = [
    'prerequisite',
    'files',
    'metadata',
    'confirm',
    'complete'
  ];

  @tracked stepIndex = 1; // FIXME 0

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
    if (this.currentStep === 'complete')                  { return; }
    if (step === this.currentStep)                        { return; }
    if (this.isFollowing(step) && step !== this.nextStep) { return; }

    this.stepIndex = this.steps.indexOf(step);

    document.documentElement.scrollTop = 0;
  }

  @action isFollowing(step) {
    return this.stepIndex < this.steps.indexOf(step);
  }
}
