import errorsFor from 'mssform/helpers/errors-for';
import totalFileSize from 'mssform/helpers/total-file-size';

import type { TOC } from '@ember/component/template-only';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

interface Signature {
  Args: {
    files: SubmissionFileData[];
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };

  Blocks: {
    default: [SubmissionFileData, SubmissionError[]];
  };
}

<template>
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
  return files.toSorted((a, b) => a.name.localeCompare(b.name));
}
