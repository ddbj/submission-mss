import errorsFor from 'mssform/helpers/errors-for';
import totalFileSize from 'mssform/helpers/total-file-size';
import { hasErrors } from 'mssform/utils/crossover-errors';

import type { TOC } from '@ember/component/template-only';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

interface Signature {
  Args: {
    files: SubmissionFileData[];
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };

  Blocks: {
    default: [SubmissionFileData, SubmissionError[]];

    // Where to put right what is wrong with the files. They came from
    // elsewhere, and nothing here can change them.
    whereToFix: [];
  };
}

<template>
  {{#if (hasErrors @files @crossoverErrors)}}
    <div class="alert alert-danger m-3" role="alert">
      {{yield to="whereToFix"}}
    </div>
  {{/if}}

  <ul class="list-group list-group-flush overflow-auto" style="max-height: 550px">
    {{#each (sortByName @files) key="name" as |file|}}
      {{yield file (errorsFor file @crossoverErrors)}}
    {{/each}}
  </ul>

  <div class="card-footer">
    {{@files.length}}
    files,
    {{totalFileSize @files}}
  </div>
</template> satisfies TOC<Signature>;

function sortByName(files: SubmissionFileData[]) {
  return [...files].sort((a, b) => a.name.localeCompare(b.name));
}
