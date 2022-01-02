import { helper } from '@ember/component/helper';
import { isNone } from '@ember/utils';

import _filesize from 'filesize';

export default helper(function filesize([bytes], opts = {}) {
  return isNone(bytes) ? null : _filesize(bytes, opts);
});
