import { helper } from '@ember/component/helper';
import { isNone } from '@ember/utils';

import { filesize, type FilesizeOptions } from 'filesize';

export default helper(function _filesize([bytes]: [number | null | undefined], opts: FilesizeOptions = {}) {
  return isNone(bytes) ? null : filesize(bytes, opts);
});
