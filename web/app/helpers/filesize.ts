import { isNone } from '@ember/utils';

import { filesize } from 'filesize';

export default function _filesize(
  byteCount: Parameters<typeof filesize>[0],
  opts: Parameters<typeof filesize>[1] = {},
): ReturnType<typeof filesize> | null {
  return isNone(byteCount) ? null : filesize(byteCount, opts);
}
