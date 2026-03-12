import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { t } from 'ember-intl';
import { task } from 'ember-concurrency';
import { eq, and, not } from 'ember-truth-helpers';
import svgJar from 'ember-svg-jar/helpers/svg-jar';

import DfastExtractor from 'mssform/components/dfast-extractor';
import FileList from 'mssform/components/file-list';
import SupportedFileTypes from 'mssform/components/file-list/supported-file-types';
import MassDirectoryExtractor from 'mssform/components/mass-directory-extractor';
import RadioGroup from 'mssform/components/radio-group';
import userMassDir from 'mssform/helpers/user-mass-dir';
import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';
import OtherPerson from 'mssform/models/other-person';

import type { paths } from 'schema/openapi';
import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';
import type RequestManager from '@ember-data/request';
import type { SubmissionFileData, SubmissionError, ParsedData } from 'mssform/models/submission-file';

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormFilesComponent extends Component<Signature> {
  @service declare requestManager: RequestManager;

  get crossoverErrors() {
    const { files } = this.args.state;
    const errors = new Map<SubmissionFileData, SubmissionError[]>();

    for (const file of files) {
      errors.set(file, []);
    }

    validatePair(errors, files);
    validateSameness(errors, files);

    return errors;
  }

  get isNextButtonEnabled() {
    const { uploadVia } = this.args.model;
    const { files } = this.args.state;

    if (!uploadVia) return false;
    if (!files.length) return false;

    for (const file of files) {
      if (file.isParsing || file.errors?.some((e) => e.severity === 'error')) return false;
    }

    for (const errs of this.crossoverErrors.values()) {
      if (errs.some((e) => e.severity === 'error')) return false;
    }

    return true;
  }

  @action setUploadVia(val: string) {
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
          <DfastExtractor @onPoll={{this.onExtractProgress}} @crossoverErrors={{this.crossoverErrors}} />
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

function validatePair(errors: Map<SubmissionFileData, SubmissionError[]>, files: SubmissionFileData[]) {
  const grouped = files.reduce((map, file) => {
    const val = map.has(file.basename) ? [...map.get(file.basename)!, file] : [file];

    return map.set(file.basename, val);
  }, new Map<string, SubmissionFileData[]>());

  for (const files of grouped.values()) {
    const [annotations, sequences] = files.reduce(
      ([ann, seq], file) => {
        return [
          file.fileType === 'annotation' ? [...ann, file] : ann,
          file.fileType === 'sequence' ? [...seq, file] : seq,
        ];
      },
      [[], []] as [SubmissionFileData[], SubmissionFileData[]],
    );

    if (!annotations.length) {
      for (const file of sequences) {
        errors.get(file)!.push({
          severity: 'error',
          id: 'submission-form.files.errors.no-annotation',
        });
      }
    }

    if (annotations.length > 1) {
      for (const file of annotations) {
        errors.get(file)!.push({
          severity: 'error',
          id: 'submission-form.files.errors.duplicate-annotations',
        });
      }
    }

    if (!sequences.length) {
      for (const file of annotations) {
        errors.get(file)!.push({
          severity: 'error',
          id: 'submission-form.files.errors.no-sequence',
        });
      }
    }

    if (sequences.length > 1) {
      for (const file of sequences) {
        errors.get(file)!.push({
          severity: 'error',
          id: 'submission-form.files.errors.duplicate-sequences',
        });
      }
    }
  }
}

function validateSameness(errors: Map<SubmissionFileData, SubmissionError[]>, files: SubmissionFileData[]) {
  const filtered = files.filter((file) => file.fileType === 'annotation' && file.isParseSucceeded);

  if (!filtered.length) return;

  const contactPersonSet = new Set<string>();
  const holdDateSet = new Set<string>();

  for (const file of filtered) {
    const { contactPerson, holdDate } = file.parsedData as ParsedData;

    contactPersonSet.add(JSON.stringify(contactPerson));
    holdDateSet.add(holdDate ?? '');
  }

  if (contactPersonSet.size > 1) {
    for (const file of filtered) {
      errors.get(file)!.push({
        severity: 'error',
        id: 'submission-form.files.errors.different-contact-person',
      });
    }
  }

  if (holdDateSet.size > 1) {
    for (const file of filtered) {
      errors.get(file)!.push({
        severity: 'error',
        id: 'submission-form.files.errors.different-hold-date',
      });
    }
  }
}
