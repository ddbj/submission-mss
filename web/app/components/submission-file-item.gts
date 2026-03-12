import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { t } from 'ember-intl';
import { formatNumber } from 'ember-intl';
import { eq, or } from 'ember-truth-helpers';
import svgJar from 'ember-svg-jar/helpers/svg-jar';

import filesize from 'mssform/helpers/filesize';

import type { TOC } from '@ember/component/template-only';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

interface Signature {
  Args: {
    file: SubmissionFileData;
    errors: SubmissionError[];
    onRemove?: (file: SubmissionFileData) => void;
  };

  Blocks: {
    prefix?: [];
  };
}

<template>
  <li class="list-group-item hstack gap-2 align-items-center">
    <div class="align-self-start">
      {{#if @file.isParsing}}
        <div class="spinner-border spinner-border-seconcary spinner-border-sm opacity-50" role="status">
          <span class="visually-hidden">{{t "file-list.item.loading"}}</span>
        </div>
      {{else}}
        {{#if (hasError @errors)}}
          {{svgJar "x-circle-fill-16" class="octicon text-danger" style="margin-top: 2.5px;"}}
        {{else if @errors.length}}
          {{svgJar "alert-fill-16" class="octicon text-warning-emphasis" style="margin-top: 2.5px;"}}
        {{else}}
          {{svgJar "check-circle-fill-16" class="octicon text-success" style="margin-top: 2.5px;"}}
        {{/if}}
      {{/if}}
    </div>

    <div class={{if @file.isParsing "opacity-50"}}>
      {{#if (has-block "prefix")}}<span class="text-body-secondary">{{yield to="prefix"}}</span>{{/if}}{{@file.name}}
      <small class="text-body-secondary">{{filesize @file.size}}</small>

      <small class="hstack gap-3 text-body-secondary">
        {{#if @file.isParsing}}
          {{t "file-list.item.loading"}}
        {{else}}
          {{#if @file.parsedData}}
            {{#if (eq @file.fileType "annotation")}}
              <div>
                <b>{{t "file-list.item.contact-person"}}</b>

                {{#let @file.parsedData.contactPerson as |person|}}
                  {{#if person}}
                    {{person.fullName}}
                    &lt;{{person.email}}&gt; ({{person.affiliation}})
                  {{else}}
                    -
                  {{/if}}
                {{/let}}
              </div>

              <div>
                <b>{{t "file-list.item.hold-date"}}</b>
                {{or @file.parsedData.holdDate "-"}}
              </div>
            {{/if}}

            {{#if (eq @file.fileType "sequence")}}
              <div>
                <b>{{t "file-list.item.entries-count"}}</b>
                {{formatNumber @file.parsedData.entriesCount}}
              </div>
            {{/if}}
          {{/if}}
        {{/if}}
      </small>

      {{#if @errors}}
        <ul class="list-unstyled">
          {{#each @errors as |error|}}
            <li class={{if (isWarning error) "text-warning-emphasis" "text-danger"}}>
              {{#if error.id}}
                {{t error.id value=error.value htmlSafe=true}}
              {{else}}
                {{error.message}}
              {{/if}}
            </li>
          {{/each}}
        </ul>
      {{/if}}
    </div>

    {{#if @onRemove}}
      <div class="ms-auto">
        <button type="button" class="btn btn-link p-2" {{on "click" (fn @onRemove @file)}}>
          {{svgJar "no-entry-24" class="octicon fill-danger" role="img" desc=(t "file-list.item.remove")}}
        </button>
      </div>
    {{/if}}
  </li>
</template> satisfies TOC<Signature>;

function hasError(errors: SubmissionError[]) {
  return errors.some((e) => e.severity === 'error');
}

function isWarning(error: SubmissionError) {
  return error.severity === 'warning';
}
