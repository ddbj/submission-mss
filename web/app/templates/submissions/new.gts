import SubmissionForm from 'mssform/components/submission-form';

import type { TOC } from '@ember/component/template-only';
import type Submission from 'mssform/models/submission';

interface Signature {
  Args: {
    model: Submission;
  };
}

<template><SubmissionForm @model={{@model}} /></template> satisfies TOC<Signature>;
