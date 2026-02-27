import { uniqueId } from '@ember/helper';
import { hash } from '@ember/helper';

import Radio from './radio';

<template>
  {{#let (uniqueId) as |name|}}
    {{yield (hash radio=(component Radio name=name))}}
  {{/let}}
</template>
