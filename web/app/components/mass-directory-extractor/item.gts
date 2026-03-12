import SubmissionFileItem from 'mssform/components/submission-file-item';
import userMassDir from 'mssform/helpers/user-mass-dir';

import type { TOC } from '@ember/component/template-only';
import type { SubmissionFile, SubmissionError } from 'mssform/models/submission-file';

interface Signature {
  Args: {
    file: SubmissionFile;
    errors: SubmissionError[];
  };
}

<template>
  <SubmissionFileItem @file={{@file}} @errors={{@errors}}>
    <:prefix>{{userMassDir}}/</:prefix>
  </SubmissionFileItem>
</template> satisfies TOC<Signature>;
