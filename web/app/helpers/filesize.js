import { helper } from '@ember/component/helper';
import { isNone } from '@ember/utils';

import { filesize } from 'filesize';

export default helper(function _filesize([bytes], opts = {}) {
  return isNone(bytes) ? null : filesize(bytes, opts);
});
