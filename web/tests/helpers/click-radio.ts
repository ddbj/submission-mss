import { click } from '@ember/test-helpers';

import findRadio from './find-radio';

export default function clickRadio(labelText: string) {
  return click(findRadio(labelText));
}
