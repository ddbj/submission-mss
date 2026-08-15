import { t } from 'ember-intl';
import svgJar from 'ember-svg-jar/helpers/svg-jar';

import FileList from 'mssform/components/file-list';
import JobIdExtractor from 'mssform/components/job-id-extractor';
import SupportedFileTypes from 'mssform/components/file-list/supported-file-types';
import MassDirectoryExtractor from 'mssform/components/mass-directory-extractor';
import RadioGroup from 'mssform/components/radio-group';
import userMassDir from 'mssform/helpers/user-mass-dir';

import type { TOC } from '@ember/component/template-only';
import type FileSelection from 'mssform/models/file-selection';

interface Signature {
  Args: {
    selection: FileSelection;
  };

  Blocks: {
    // Shown above the choices, where the form has something to say about them.
    question?: [];

    // Shown above the file list, which the two forms introduce differently.
    instructions?: [];
  };
}

// How a form's files are chosen: an extraction to import them from, or the
// files themselves. Both forms that collect files use this; what they do with
// the selection afterwards is their own.
<template>
  <div class="vstack gap-3">
    <div class="card">
      <div class="card-body">
        {{yield to="question"}}

        <RadioGroup as |group|>
          <div class="form-check">
            <group.radio as |radio|>
              <radio.input
                checked={{eq @selection.via "dfast"}}
                required
                class="form-check-input"
                {{on "change" (fn @selection.setVia "dfast")}}
              />

              <radio.label class="form-check-label">
                {{t "submission-form.files.a1"}}
              </radio.label>
            </group.radio>
          </div>

          <div class="form-check">
            <group.radio as |radio|>
              <radio.input
                checked={{eq @selection.via "ggs"}}
                required
                class="form-check-input"
                {{on "change" (fn @selection.setVia "ggs")}}
              />

              <radio.label class="form-check-label">
                {{t "submission-form.files.a4"}}
              </radio.label>
            </group.radio>
          </div>

          <div class="form-check">
            <group.radio as |radio|>
              <radio.input
                checked={{eq @selection.via "webui"}}
                required
                class="form-check-input"
                {{on "change" (fn @selection.setVia "webui")}}
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
                  checked={{eq @selection.via "mass_directory"}}
                  required
                  class="form-check-input"
                  {{on "change" (fn @selection.setVia "mass_directory")}}
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

    {{#if (eq @selection.via "dfast")}}
      <JobIdExtractor
        @endpoint="/dfast_extractions"
        @i18nPrefix="dfast-extractor"
        @onPoll={{@selection.onExtractProgress}}
        @crossoverErrors={{@selection.crossoverErrors}}
      />
    {{else if (eq @selection.via "ggs")}}
      <JobIdExtractor
        @endpoint="/ggs_extractions"
        @i18nPrefix="ggs-extractor"
        @onPoll={{@selection.onExtractProgress}}
        @crossoverErrors={{@selection.crossoverErrors}}
      />
    {{else if (eq @selection.via "webui")}}
      <div class="card">
        <div class="card-body">
          {{yield to="instructions"}}

          <SupportedFileTypes />

          <FileList
            @files={{@selection.files}}
            @crossoverErrors={{@selection.crossoverErrors}}
            @onAdd={{@selection.addFile}}
            @onRemove={{@selection.removeFile}}
          />
        </div>
      </div>
    {{else if (eq @selection.via "mass_directory")}}
      <MassDirectoryExtractor
        @onPoll={{@selection.onExtractProgress}}
        @crossoverErrors={{@selection.crossoverErrors}}
      />
    {{/if}}
  </div>
</template> satisfies TOC<Signature>;
