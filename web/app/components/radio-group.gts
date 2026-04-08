import { uniqueId } from '@ember/helper';
import { hash } from '@ember/helper';

import Radio from './radio';

import type { TOC } from '@ember/component/template-only';
import type { WithBoundArgs } from '@glint/template';

interface Signature {
  Blocks: {
    default: [{ radio: WithBoundArgs<typeof Radio, 'name'> }];
  };
}

<template>
  {{#let (uniqueId) as |name|}}
    {{yield (hash radio=(component Radio name=name))}}
  {{/let}}
</template> satisfies TOC<Signature>;
