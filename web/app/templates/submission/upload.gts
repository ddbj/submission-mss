import UploadForm from 'mssform/components/upload-form';

import type { TOC } from '@ember/component/template-only';
import type Submission from 'mssform/models/submission';

interface Signature {
  Args: {
    model: Submission;
  };
}

<template><UploadForm @model={{@model}} /></template> satisfies TOC<Signature>;
