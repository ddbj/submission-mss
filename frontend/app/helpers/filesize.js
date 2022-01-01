import { helper } from '@ember/component/helper';

import _filesize from 'filesize';

export default helper(function filesize([bytes], opts = {}) {
  return _filesize(bytes, opts);
});
