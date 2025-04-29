import { isNone } from '@ember/utils';

export default function _isNone(obj: Parameters<typeof isNone>[0]) {
  return isNone(obj);
}
