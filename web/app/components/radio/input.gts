import type { TOC } from '@ember/component/template-only';

interface Signature {
  Element: HTMLInputElement;
  Args: {
    name: string;
    id: string;
  };
}

<template><input type="radio" name={{@name}} id={{@id}} ...attributes /></template> satisfies TOC<Signature>;
