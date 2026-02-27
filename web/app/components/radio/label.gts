import type { TOC } from '@ember/component/template-only';

interface Signature {
  Element: HTMLLabelElement;
  Args: {
    for: string;
  };
  Blocks: {
    default: [];
  };
}

<template>
  <label for={{@for}} ...attributes>
    {{yield}}
  </label>
</template> satisfies TOC<Signature>;
