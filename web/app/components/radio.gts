import { uniqueId } from '@ember/helper';
import { hash } from '@ember/helper';

import RadioInput from './radio/input';
import RadioLabel from './radio/label';

import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

interface Signature {
  Args: {
    name: string;
  };
  Blocks: {
    default: [
      {
        input: ComponentLike<{ Element: HTMLInputElement }>;
        label: ComponentLike<{ Element: HTMLLabelElement; Blocks: { default: [] } }>;
      },
    ];
  };
}

<template>
  {{#let (uniqueId) as |id|}}
    {{yield (hash input=(component RadioInput name=@name id=id) label=(component RadioLabel for=id))}}
  {{/let}}
</template> satisfies TOC<Signature>;
