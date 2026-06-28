import SubmissionFileItem from 'mssform/components/submission-file-item';

import type { TOC } from '@ember/component/template-only';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

interface Signature {
  Args: {
    file: SubmissionFileData;
    errors: SubmissionError[];
  };
}

<template>
  <SubmissionFileItem @file={{@file}} @errors={{@errors}}>
    <:prefix>{{@file.jobId}}/</:prefix>
  </SubmissionFileItem>
</template> satisfies TOC<Signature>;
