import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { t } from 'ember-intl';
import { task } from 'ember-concurrency';
import svgJar from 'ember-svg-jar/helpers/svg-jar';

import FileList from 'mssform/components/file-list';
import JobIdExtractor from 'mssform/components/job-id-extractor';
import SupportedFileTypes from 'mssform/components/file-list/supported-file-types';
import MassDirectoryExtractor from 'mssform/components/mass-directory-extractor';
import RadioGroup from 'mssform/components/radio-group';
import userMassDir from 'mssform/helpers/user-mass-dir';
import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';
import OtherPerson from 'mssform/models/other-person';
import { discardFiles } from 'mssform/models/submission-file';
import {
  collectCrossoverErrors,
  hasBlockingErrors,
  validateDuplicates,
  validatePairs,
  validateSameness,
} from 'mssform/utils/crossover-errors';

import type { paths } from 'schema/openapi';
import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';
import type { RequestManager } from '@warp-drive/core';
import type { SubmissionFileData } from 'mssform/models/submission-file';

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormFilesComponent extends Component<Signature> {
  @service declare requestManager: RequestManager;

  // A new submission has to arrive complete: whole pairs, agreeing with each
  // other.
  get crossoverErrors() {
    return collectCrossoverErrors(this.args.state.files, [validateDuplicates, validatePairs, validateSameness]);
  }

  get isNextButtonEnabled() {
    const { uploadVia } = this.args.model;
    const { files } = this.args.state;

    if (!uploadVia) return false;
    if (!files.length) return false;

    return !hasBlockingErrors(files, this.crossoverErrors);
  }

  @action setUploadVia(val: string) {
    discardFiles(this.args.state.files);

    this.args.model.uploadVia = val;
    this.args.model.extractionId = undefined;
    this.args.state.files = [];
  }

  @action onExtractProgress({ id, files }: { id: number; files: SubmissionFileData[] }) {
    this.args.model.extractionId = id;
    this.args.state.files = files;
  }

  @action addFile(file: SubmissionFileData) {
    this.args.state.files = [...this.args.state.files, file];
  }

  @action removeFile(file: SubmissionFileData) {
    discardFiles([file]);

    this.args.state.files = this.args.state.files.filter((f) => f !== file);
  }

  @action handleSubmit(event: Event) {
    event.preventDefault();
    void this.goNext.perform();
  }

  goNext = task({ drop: true }, async () => {
    await this.fillDataFromLastSubmission();
    this.fillDataFromSubmissionFiles();

    this.args.nav.goNext();
  });

  async fillDataFromLastSubmission() {
    type LastSubmitted = paths['/submissions/last_submitted']['get']['responses']['200']['content']['application/json'];

    let last: LastSubmitted['submission'] | undefined;

    try {
      const { content } = await this.requestManager.request<LastSubmitted>({
        url: '/submissions/last_submitted',
        suppressErrorModal: true,
      });

      last = content.submission;
    } catch {
      // do nothing
    }

    if (!last) return;

    const { model } = this.args;

    model.contactPerson.email = last.contact_person.email;
    model.contactPerson.fullName = last.contact_person.full_name;
    model.contactPerson.affiliation = last.contact_person.affiliation;

    model.otherPeople = last.other_people.map(({ email, full_name }) => {
      const person = new OtherPerson();

      return Object.assign(person, { email, fullName: full_name });
    });

    if (!model.sequencer) {
      model.sequencer = last.sequencer;
    }

    if (!model.emailLanguage) {
      model.emailLanguage = last.email_language;
    }
  }

  fillDataFromSubmissionFiles() {
    const { state, model } = this.args;
    const { files } = state;

    const annotationFile = files.find((file) => file.fileType === 'annotation');

    const { contactPerson, holdDate } = annotationFile?.parsedData ?? {};

    Object.assign(model.contactPerson, contactPerson ?? {});

    model.holdDate = holdDate ?? undefined;

    model.entriesCount = files
      .filter((file) => file.fileType === 'sequence')
      .reduce((acc, file) => {
        return acc + (file.parsedData?.entriesCount ?? 0);
      }, 0);
  }

  <template>
    <form {{on "submit" this.handleSubmit}} {{leavingConfirmation}}>
      <div class="vstack gap-3">
        <div class="card">
          <div class="card-body">
            {{t "submission-form.files.q-html" htmlSafe=true}}

            <RadioGroup as |group|>
              <div class="form-check">
                <group.radio as |radio|>
                  <radio.input
                    checked={{eq @model.uploadVia "dfast"}}
                    required
                    class="form-check-input"
                    {{on "change" (fn this.setUploadVia "dfast")}}
                  />

                  <radio.label class="form-check-label">
                    {{t "submission-form.files.a1"}}
                  </radio.label>
                </group.radio>
              </div>

              <div class="form-check">
                <group.radio as |radio|>
                  <radio.input
                    checked={{eq @model.uploadVia "ggs"}}
                    required
                    class="form-check-input"
                    {{on "change" (fn this.setUploadVia "ggs")}}
                  />

                  <radio.label class="form-check-label">
                    {{t "submission-form.files.a4"}}
                  </radio.label>
                </group.radio>
              </div>

              <div class="form-check">
                <group.radio as |radio|>
                  <radio.input
                    checked={{eq @model.uploadVia "webui"}}
                    required
                    class="form-check-input"
                    {{on "change" (fn this.setUploadVia "webui")}}
                  />

                  <radio.label class="form-check-label">
                    {{t "submission-form.files.a2"}}
                  </radio.label>
                </group.radio>
              </div>

              <div class="hstack gap-3">
                <div class="form-check">
                  <group.radio as |radio|>
                    <radio.input
                      checked={{eq @model.uploadVia "mass_directory"}}
                      required
                      class="form-check-input"
                      {{on "change" (fn this.setUploadVia "mass_directory")}}
                    />

                    <radio.label class="form-check-label">
                      {{t "submission-form.files.a3-html" htmlSafe=true userMassDir=(userMassDir)}}
                    </radio.label>

                    {{t "submission-form.files.a3-note-html" htmlSafe=true}}
                  </group.radio>
                </div>

                <small>
                  <a href={{t "submission-form.files.a3-help-url"}} target="_blank" rel="noopener noreferrer">
                    {{svgJar "question-16" class="octicon" width="14px" style="margin-top: 2px"}}
                    {{t "submission-form.files.a3-help-text"}}
                  </a>
                </small>
              </div>
            </RadioGroup>
          </div>
        </div>

        {{#if (eq @model.uploadVia "dfast")}}
          <JobIdExtractor
            @endpoint="/dfast_extractions"
            @i18nPrefix="dfast-extractor"
            @onPoll={{this.onExtractProgress}}
            @crossoverErrors={{this.crossoverErrors}}
          />
        {{else if (eq @model.uploadVia "ggs")}}
          <JobIdExtractor
            @endpoint="/ggs_extractions"
            @i18nPrefix="ggs-extractor"
            @onPoll={{this.onExtractProgress}}
            @crossoverErrors={{this.crossoverErrors}}
          />
        {{else if (eq @model.uploadVia "webui")}}
          <div class="card">
            <div class="card-body">
              {{t "submission-form.files.instructions-html" htmlSafe=true}}

              <SupportedFileTypes />

              <FileList
                @files={{@state.files}}
                @crossoverErrors={{this.crossoverErrors}}
                @onAdd={{this.addFile}}
                @onRemove={{this.removeFile}}
              />
            </div>
          </div>
        {{else if (eq @model.uploadVia "mass_directory")}}
          <MassDirectoryExtractor @onPoll={{this.onExtractProgress}} @crossoverErrors={{this.crossoverErrors}} />
        {{/if}}
      </div>

      <hr />

      <div class="hstack gap-3 justify-content-end">
        <button type="button" class="btn btn-outline-primary px-4" {{on "click" @nav.goPrev}}>
          {{t "submission-form.nav.back"}}
        </button>

        <button
          type="submit"
          class="btn btn-primary px-5"
          disabled={{not (and this.isNextButtonEnabled this.goNext.isIdle)}}
        >{{t "submission-form.nav.next"}}</button>
      </div>
    </form>
  </template>
}
