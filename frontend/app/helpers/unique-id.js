import { guidFor } from '@ember/object/internals';
import { helper } from '@ember/component/helper';

export default helper(function uniqueId() {
  return guidFor({});
});
