import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import { eq, and } from 'ember-truth-helpers';
import svgJar from 'ember-svg-jar/helpers/svg-jar';

import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';
import RadioGroup from 'mssform/components/radio-group';

import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormPrerequisiteComponent extends Component<Signature> {
  @action setMaybeTpa(val: boolean) {
    this.args.state.maybeTpa = val;
    this.args.model.tpa = val ? null : false;
  }

  @action setTpa(value: boolean) {
    this.args.model.tpa = value;
  }

  @action handleSubmit(event: Event) {
    event.preventDefault();
    this.args.nav.goNext();
  }

  <template>
    {{t "submission-form.prerequisite.instructions-html" htmlSafe=true}}

    <form {{on "submit" this.handleSubmit}} {{leavingConfirmation}}>
      <div class="vstack gap-3">
        <div class="card">
          <div class="card-body">
            <p>{{t "submission-form.prerequisite.q-1"}}</p>

            <RadioGroup as |group|>
              <div class="form-check">
                <group.radio as |radio|>
                  <radio.input
                    checked={{eq @state.maybeTpa false}}
                    required
                    class="form-check-input"
                    {{on "change" (fn this.setMaybeTpa false)}}
                  />

                  <radio.label class="form-check-label">
                    {{t "submission-form.prerequisite.a1-1"}}
                  </radio.label>
                </group.radio>
              </div>

              <div class="hstack gap-3">
                <div class="form-check">
                  <group.radio as |radio|>
                    <radio.input
                      checked={{eq @state.maybeTpa true}}
                      required
                      class="form-check-input"
                      {{on "change" (fn this.setMaybeTpa true)}}
                    />

                    <radio.label class="form-check-label">
                      {{t "submission-form.prerequisite.a1-2"}}
                    </radio.label>
                  </group.radio>
                </div>

                <small>
                  <a href={{t "submission-form.prerequisite.about-tpa-url"}} target="_blank" rel="noopener noreferrer">
                    {{svgJar "question-16" class="octicon" width="14px" style="margin-top: 2px"}}
                    {{t "submission-form.prerequisite.about-tpa"}}
                  </a>
                </small>
              </div>
            </RadioGroup>
          </div>
        </div>

        {{#if @state.maybeTpa}}
          <div class="card">
            <div class="card-body">
              <p>{{t "submission-form.prerequisite.q-2"}}</p>

              <RadioGroup as |group|>
                <div class="form-check">
                  <group.radio as |radio|>
                    <radio.input
                      checked={{eq @model.tpa true}}
                      required
                      class="form-check-input"
                      {{on "change" (fn this.setTpa true)}}
                    />

                    <radio.label class="form-check-label">
                      {{t "submission-form.prerequisite.a2-1"}}
                    </radio.label>
                  </group.radio>
                </div>

                <div class="form-check">
                  <group.radio as |radio|>
                    <radio.input
                      checked={{eq @model.tpa false}}
                      required
                      class="form-check-input"
                      {{on "change" (fn this.setTpa false)}}
                    />

                    <radio.label class="form-check-label">
                      {{t "submission-form.prerequisite.a2-2"}}
                    </radio.label>
                  </group.radio>
                </div>
              </RadioGroup>
            </div>
          </div>
        {{/if}}
      </div>

      <hr />

      {{#if (and @state.maybeTpa (eq @model.tpa false))}}
        <p>{{t "submission-form.prerequisite.unacceptable"}}</p>

        <LinkTo @route="home">{{t "go-to-home"}}</LinkTo>
      {{else}}
        <div class="hstack gap-3 justify-content-end">
          <button type="submit" class="btn btn-primary px-5">{{t "submission-form.nav.next"}}</button>
        </div>
      {{/if}}
    </form>
  </template>
}
