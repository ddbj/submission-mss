import Component from '@glimmer/component';
import { fn, concat } from '@ember/helper';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { t } from 'ember-intl';
import pageTitle from 'ember-page-title/helpers/page-title';

import Complete from './submission-form/complete';
import Confirm from './submission-form/confirm';
import Files from './submission-form/files';
import Metadata from './submission-form/metadata';
import Prerequisite from './submission-form/prerequisite';
import stepNavLinkClass from 'mssform/helpers/step-nav-link-class';

import type { ComponentLike } from '@glint/template';
import type RouterService from '@ember/routing/router-service';
import type Submission from 'mssform/models/submission';
import type { SubmissionFile } from 'mssform/models/submission-file';

const COMPONENTS: Record<string, unknown> = {
  prerequisite: Prerequisite,
  files: Files,
  metadata: Metadata,
  confirm: Confirm,
  complete: Complete,
};

export interface Signature {
  Args: {
    model: Submission;
  };
}

export default class SubmissionFormComponent extends Component<Signature> {
  @service declare router: RouterService;

  state = new State();
  nav = new Navigation();

  get component() {
    return COMPONENTS[this.nav.currentStep] as ComponentLike<{
      Args: { model: Submission; state: State; nav: Navigation };
    }>;
  }

  <template>
    {{pageTitle (t "submission-form.title")}}

    <style {{! template-lint-disable no-forbidden-elements }}>
      body {
        counter-reset: step 0;
      }

      nav > .nav-link:before {
        counter-increment: step 1;
        content: counter(step) ". ";
      }
    </style>

    <h1 class="display-6 my-4">{{t "submission-form.title"}}</h1>

    <div class="row my-3">
      <div class="col-3">
        <nav class="nav nav-pills flex-column">
          {{#each this.nav.steps as |step|}}
            <button
              type="button"
              class="nav-link text-start {{stepNavLinkClass this.nav step}}"
              {{on "click" (fn this.nav.gotoStep step)}}
            >
              {{t (concat "submission-form.steps." step)}}
            </button>
          {{/each}}
        </nav>
      </div>

      <main class="col">
        <this.component @model={{@model}} @state={{this.state}} @nav={{this.nav}} />
      </main>
    </div>
  </template>
}

export class State {
  @tracked maybeTpa: boolean | null = null;
  @tracked files: SubmissionFile[] = [];
}

export class Navigation {
  steps = ['prerequisite', 'files', 'metadata', 'confirm', 'complete'] as const;

  @tracked stepIndex = 0;

  get currentStep(): string {
    return this.steps[this.stepIndex]!;
  }

  get prevStep(): string {
    const i = Math.max(0, this.stepIndex - 1);

    return this.steps[i]!;
  }

  get nextStep(): string {
    const i = Math.min(this.stepIndex + 1, this.steps.length - 1);

    return this.steps[i]!;
  }

  @action goNext() {
    this.gotoStep(this.nextStep);
  }

  @action goPrev() {
    this.gotoStep(this.prevStep);
  }

  @action gotoStep(step: string) {
    if (this.currentStep === 'complete') return;
    if (step === this.currentStep) return;
    if (this.isFollowing(step) && step !== this.nextStep) return;

    this.stepIndex = this.steps.indexOf(step as (typeof this.steps)[number]);

    document.documentElement.scrollTop = 0;
  }

  @action isFollowing(step: string) {
    return this.stepIndex < this.steps.indexOf(step as (typeof this.steps)[number]);
  }
}
