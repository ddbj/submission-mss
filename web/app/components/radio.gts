import { uniqueId } from '@ember/helper';
import { hash } from '@ember/helper';

import RadioInput from './radio/input';
import RadioLabel from './radio/label';

<template>
  {{#let (uniqueId) as |id|}}
    {{yield (hash input=(component RadioInput name=@name id=id) label=(component RadioLabel for=id))}}
  {{/let}}
</template>
