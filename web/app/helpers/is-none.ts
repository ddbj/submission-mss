import { helper } from '@ember/component/helper';
import { isNone } from '@ember/utils';

export default helper(function _isNone([obj]: [unknown]) {
  return isNone(obj);
});
